# Diagnostics ------------------------------------------------------------------
#
# Structural diagnostics for understanding keyed data.
# No value diffs, just summaries.

#' Get key status summary
#'
#' Returns diagnostic information about a keyed data frame.
#'
#' @param .data A data frame.
#'
#' @return A key status object with diagnostic information.
#'
#' @examples
#' df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
#' key_status(df)
#'
#' @export
key_status <- function(.data) {
  is_keyed <- has_key(.data)
  key_cols <- get_key_cols(.data)

  status <- list(
    is_keyed = is_keyed,
    key_cols = key_cols,
    nrow = nrow(.data),
    ncol = ncol(.data),
    colnames = names(.data),
    has_row_id = has_row_id(.data),
    has_snapshot = !is.null(attr(.data, "keyed_snapshot_ref"))
  )

  if (is_keyed && !is.null(key_cols)) {
    # Check if key is still valid
    if (all(key_cols %in% names(.data))) {
      key_vals <- .data[key_cols]
      n_unique <- vctrs::vec_unique_count(key_vals)
      status$key_valid <- n_unique == nrow(.data)
      status$key_unique_count <- n_unique
      status$key_na_count <- sum(rowSums(is.na(key_vals)) > 0)
    } else {
      status$key_valid <- FALSE
      status$key_missing_cols <- setdiff(key_cols, names(.data))
    }
  }

  structure(status, class = "keyed_status")
}

#' @export
print.keyed_status <- function(x, ...) {
  cli::cli_h3("Key Status")

  if (x$is_keyed) {
    cli::cli_text("Key: {.field {paste(x$key_cols, collapse = ', ')}}")
    if (isTRUE(x$key_valid)) {
      cli::cli_alert_success("Key is valid and unique")
    } else if (isFALSE(x$key_valid)) {
      if (!is.null(x$key_missing_cols)) {
        cli::cli_alert_danger("Key columns missing: {paste(x$key_missing_cols, collapse = ', ')}")
      } else {
        n_dups <- x$nrow - x$key_unique_count
        cli::cli_alert_warning("Key has {n_dups} duplicate(s)")
      }
    }
    if (!is.null(x$key_na_count) && x$key_na_count > 0) {
      cli::cli_alert_warning("{x$key_na_count} row(s) with NA in key")
    }
  } else {
    cli::cli_text("No key defined")
  }

  cli::cli_text("Rows: {x$nrow}, Columns: {x$ncol}")

  if (x$has_row_id) {
    cli::cli_text("{.emph (has row IDs)}")
  }
  if (x$has_snapshot) {
    cli::cli_text("{.emph (has snapshot reference)}")
  }

  invisible(x)
}

#' Compare structure of two data frames
#'
#' Compares the structural properties of two data frames without
#' comparing actual values. Useful for detecting schema drift.
#'
#' @param x First data frame.
#' @param y Second data frame.
#'
#' @return A structure comparison object.
#'
#' @examples
#' df1 <- data.frame(id = 1:3, x = c("a", "b", "c"))
#' df2 <- data.frame(id = 1:5, x = c("a", "b", "c", "d", "e"), y = 1:5)
#' compare_structure(df1, df2)
#'
#' @export
compare_structure <- function(x, y) {
  comparison <- list(
    # Row counts
    nrow_x = nrow(x),
    nrow_y = nrow(y),
    nrow_diff = nrow(y) - nrow(x),

    # Column comparison
    cols_x = names(x),
    cols_y = names(y),
    cols_added = setdiff(names(y), names(x)),
    cols_removed = setdiff(names(x), names(y)),
    cols_common = intersect(names(x), names(y)),

    # Type comparison for common columns
    type_changes = list(),

    # Key comparison
    key_x = get_key_cols(x),
    key_y = get_key_cols(y),
    key_changed = !identical(get_key_cols(x), get_key_cols(y))
  )

  # Check type changes
  for (col in comparison$cols_common) {
    type_x <- class(x[[col]])[1]
    type_y <- class(y[[col]])[1]
    if (type_x != type_y) {
      comparison$type_changes[[col]] <- list(from = type_x, to = type_y)
    }
  }

  # Overall similarity
  comparison$identical_structure <- (
    length(comparison$cols_added) == 0 &&
    length(comparison$cols_removed) == 0 &&
    length(comparison$type_changes) == 0
  )

  structure(comparison, class = "keyed_structure_comparison")
}

#' @export
print.keyed_structure_comparison <- function(x, ...) {
  cli::cli_h3("Structure Comparison")

  # Row counts
  if (x$nrow_diff != 0) {
    sign <- if (x$nrow_diff > 0) "+" else ""
    cli::cli_alert_info("Rows: {x$nrow_x} -> {x$nrow_y} ({sign}{x$nrow_diff})")
  } else {
    cli::cli_text("Rows: {x$nrow_x} (unchanged)")
  }

  # Column changes
  if (length(x$cols_added) > 0) {
    cli::cli_alert_info("Columns added: {.field {paste(x$cols_added, collapse = ', ')}}")
  }
  if (length(x$cols_removed) > 0) {
    cli::cli_alert_warning("Columns removed: {.field {paste(x$cols_removed, collapse = ', ')}}")
  }

  # Type changes
  if (length(x$type_changes) > 0) {
    cli::cli_alert_warning("Type changes:")
    for (col in names(x$type_changes)) {
      change <- x$type_changes[[col]]
      cli::cli_text("  {.field {col}}: {change$from} -> {change$to}")
    }
  }

  # Key changes
  if (x$key_changed) {
    key_x_str <- if (is.null(x$key_x)) "none" else paste(x$key_x, collapse = ", ")
    key_y_str <- if (is.null(x$key_y)) "none" else paste(x$key_y, collapse = ", ")
    cli::cli_alert_warning("Key changed: {key_x_str} -> {key_y_str}")
  }

  if (x$identical_structure) {
    cli::cli_alert_success("Structure identical")
  }

  invisible(x)
}

#' Compare key values between two data frames
#'
#' Identifies keys that are new, removed, or common between two keyed
#' data frames. Does not compare values, only key membership.
#'
#' @param x First keyed data frame.
#' @param y Second keyed data frame.
#' @param by Column(s) to compare. If NULL, uses the key from x.
#'
#' @return A key comparison object.
#'
#' @examples
#' df1 <- key(data.frame(id = 1:3, x = 1:3), id)
#' df2 <- key(data.frame(id = 2:4, x = 2:4), id)
#' compare_keys(df1, df2)
#'
#' @export
compare_keys <- function(x, y, by = NULL) {
  # Determine comparison columns
  if (is.null(by)) {
    by <- get_key_cols(x)
    if (is.null(by)) {
      abort("No key defined on x. Specify `by` or use key().")
    }
  }

  # Check columns exist
  if (!all(by %in% names(x))) {
    abort(c("Column(s) not found in x:", setdiff(by, names(x))))
  }
  if (!all(by %in% names(y))) {
    abort(c("Column(s) not found in y:", setdiff(by, names(y))))
  }

  # Extract key values
  keys_x <- unique(x[by])
  keys_y <- unique(y[by])

  # Find differences using vctrs
  in_both <- vctrs::vec_in(keys_x, keys_y)
  in_x_only <- keys_x[!in_both, , drop = FALSE]

  in_both_y <- vctrs::vec_in(keys_y, keys_x)
  in_y_only <- keys_y[!in_both_y, , drop = FALSE]

  common_keys <- keys_x[in_both, , drop = FALSE]

  comparison <- list(
    by = by,
    n_x = nrow(keys_x),
    n_y = nrow(keys_y),
    n_common = nrow(common_keys),
    n_only_x = nrow(in_x_only),
    n_only_y = nrow(in_y_only),
    keys_only_x = in_x_only,
    keys_only_y = in_y_only,
    overlap_pct = if (nrow(keys_x) > 0) nrow(common_keys) / nrow(keys_x) * 100 else 100
  )

  structure(comparison, class = "keyed_key_comparison")
}

#' @export
print.keyed_key_comparison <- function(x, ...) {
  cli::cli_h3("Key Comparison")
  cli::cli_text("Comparing on: {.field {paste(x$by, collapse = ', ')}}")
  cli::cli_text("")
  cli::cli_text("x: {x$n_x} unique keys")
  cli::cli_text("y: {x$n_y} unique keys")
  cli::cli_text("")
  cli::cli_text("Common: {x$n_common} ({sprintf('%.1f%%', x$overlap_pct)} of x)")
  cli::cli_text("Only in x: {x$n_only_x}")
  cli::cli_text("Only in y: {x$n_only_y}")

  if (x$n_only_x > 0 && x$n_only_x <= 5) {
    cli::cli_text("")
    cli::cli_text("Keys only in x:")
    print(x$keys_only_x, n = 5)
  }
  if (x$n_only_y > 0 && x$n_only_y <= 5) {
    cli::cli_text("")
    cli::cli_text("Keys only in y:")
    print(x$keys_only_y, n = 5)
  }

  invisible(x)
}

#' Find duplicate keys
#'
#' Identifies rows with duplicate key values.
#'
#' @param .data A data frame.
#' @param ... Column names to check. If empty, uses the key columns.
#'
#' @return Data frame containing only the rows with duplicate keys,
#'   with a `.n` column showing the count.
#'
#' @examples
#' df <- data.frame(id = c(1, 1, 2, 3, 3, 3), x = letters[1:6])
#' find_duplicates(df, id)
#'
#' @export
find_duplicates <- function(.data, ...) {
  cols <- key_cols_from_dots(.data, ...)

  if (length(cols) == 0) {
    cols <- get_key_cols(.data)
    if (is.null(cols)) {
      abort("No columns specified and no key defined.")
    }
  }

  # Count occurrences
  counts <- dplyr::count(.data, dplyr::across(dplyr::all_of(cols)), name = ".n")
  dups <- counts[counts$.n > 1, , drop = FALSE]

  if (nrow(dups) == 0) {
    cli::cli_alert_success("No duplicates found")
    return(invisible(dups))
  }

  # Return full rows for duplicates
  dplyr::semi_join(.data, dups, by = cols) |>
    dplyr::left_join(dups, by = cols) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(cols)))
}
