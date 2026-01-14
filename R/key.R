# Key Definition ---------------------------------------------------------------

#' Define a key for a data frame
#'
#' Attaches key metadata to a data frame, marking which column(s) form the
#' unique identifier for rows. Keys are validated for uniqueness at creation.
#'
#' @param .data A data frame or tibble.
#' @param ... Column names (unquoted) that form the key. Can be a single column
#'   or multiple columns for a composite key.
#' @param .validate If `TRUE` (default), check that the key is unique.
#' @param .strict If `TRUE`, error on non-unique keys. If `FALSE` (default),

#'   warn but still attach the key.
#'
#' @return A keyed data frame (class `keyed_df`).
#'
#' @examples
#' df <- data.frame(id = 1:3, x = c("a", "b", "c"))
#' key(df, id)
#'
#' # Composite key
#' df2 <- data.frame(country = c("US", "US", "UK"), year = c(2020, 2021, 2020), val = 1:3)
#' key(df2, country, year)
#'
#' @export
key <- function(.data, ..., .validate = TRUE, .strict = FALSE) {
  key_cols <- key_cols_from_dots(.data, ...)

  if (length(key_cols) == 0) {
    abort("At least one key column must be specified.")
  }

  # Check columns exist

  missing <- setdiff(key_cols, names(.data))
  if (length(missing) > 0) {
    abort(c(
      "Key column(s) not found in data:",
      paste0("- ", missing)
    ))
  }

  # Validate uniqueness

  if (.validate) {
    validate_key_uniqueness(.data, key_cols, strict = .strict)
  }


  # Attach key metadata
  new_keyed_df(.data, key_cols)
}

#' @rdname key
#' @param value Character vector of column names to use as key.
#' @export
`key<-` <- function(.data, value) {
  if (!is.character(value)) {
    abort("`value` must be a character vector of column names.")
  }
  key(.data, !!!rlang::syms(value))
}

#' Remove key from a data frame
#'
#' @param .data A keyed data frame.
#' @return A tibble without key metadata.
#' @export
unkey <- function(.data) {
  attr(.data, "keyed_cols") <- NULL
  attr(.data, "keyed_hash") <- NULL
  class(.data) <- setdiff(class(.data), "keyed_df")
  .data
}

#' Check if data frame has a key
#'
#' @param .data A data frame.
#' @return Logical.
#' @export
has_key <- function(.data) {
  inherits(.data, "keyed_df") && !is.null(attr(.data, "keyed_cols"))
}

#' Get key column names
#'
#' @param .data A keyed data frame.
#' @return Character vector of column names, or NULL if no key.
#' @export
get_key_cols <- function(.data) {
  attr(.data, "keyed_cols")
}

#' Check if the key is still valid
#'
#' Checks whether the key columns still exist and are still unique.
#'
#' @param .data A keyed data frame.
#' @return Logical. Returns FALSE with a warning if key is invalid.
#' @export
key_is_valid <- function(.data) {
  if (!has_key(.data)) {
    return(FALSE)
  }

  key_cols <- get_key_cols(.data)

  # Check columns still exist
  if (!all(key_cols %in% names(.data))) {
    warn("Key column(s) no longer present in data.")
    return(FALSE)

  }

  # Check uniqueness
  key_vals <- .data[key_cols]
  n_unique <- vctrs::vec_unique_count(key_vals)
  if (n_unique != nrow(.data)) {
    warn("Key is no longer unique.")
    return(FALSE)
  }

  TRUE
}


# Constructor ------------------------------------------------------------------

#' Create a keyed data frame
#'
#' Low-level constructor for keyed_df class.
#'
#' @param x A data frame.
#' @param key_cols Character vector of column names forming the key.
#' @return A keyed_df object.
#' @noRd
new_keyed_df <- function(x, key_cols) {
  x <- tibble::as_tibble(x)
  attr(x, "keyed_cols") <- key_cols
  class(x) <- c("keyed_df", class(x))
  x
}

#' Restore keyed_df after transformation
#'
#' Re-attaches key metadata if key columns still exist and are unique.
#'
#' @param x Transformed data.
#' @param key_cols Original key column names.
#' @return keyed_df if valid, otherwise plain tibble with warning.
#' @noRd
restore_keyed_df <- function(x, key_cols) {
  # Check if key columns still exist
  if (!all(key_cols %in% names(x))) {
    warn(c(
      "Key column(s) lost during transformation.",
      i = paste("Expected:", paste(key_cols, collapse = ", "))
    ))
    return(tibble::as_tibble(x))
  }

  # Check uniqueness (silently return plain tibble if not unique)
  key_vals <- x[key_cols]
  n_unique <- vctrs::vec_unique_count(key_vals)
  if (n_unique != nrow(x)) {
    warn("Key is no longer unique after transformation.")
    return(tibble::as_tibble(x))
  }

  new_keyed_df(x, key_cols)
}


# Helpers ----------------------------------------------------------------------

#' Extract column names from tidy-select dots
#' @noRd
key_cols_from_dots <- function(.data, ...) {
  dots <- enquos(...)
  if (length(dots) == 0) {
    return(character())
  }
  unname(vapply(dots, function(q) as_label(q), character(1)))
}

#' Validate that key columns are unique
#' @noRd
validate_key_uniqueness <- function(.data, key_cols, strict = FALSE) {
  key_vals <- .data[key_cols]
  n_rows <- nrow(.data)
  n_unique <- vctrs::vec_unique_count(key_vals)

  if (n_unique != n_rows) {
    n_dups <- n_rows - n_unique
    msg <- c(
      "Key is not unique.",
      i = paste0(n_dups, " duplicate key value(s) found."),
      i = paste("Key columns:", paste(key_cols, collapse = ", "))
    )
    if (strict) {
      abort(msg)
    } else {
      warn(msg)
    }
  }

  invisible(TRUE)
}


# Print method -----------------------------------------------------------------

#' @export
print.keyed_df <- function(x, ...) {
  # Just use tibble's print - tbl_sum adds key info to header

  NextMethod()
}

#' @importFrom pillar tbl_sum
#' @export
tbl_sum.keyed_df <- function(x, ...) {
  key_cols <- get_key_cols(x)
  key_str <- if (!is.null(key_cols)) paste(key_cols, collapse = ", ") else "none"
  if (has_id(x)) key_str <- paste0(key_str, " | .id")

  c(
    "A keyed tibble" = paste0(nrow(x), " x ", ncol(x)),
    "Key" = key_str
  )
}

#' Summary method for keyed data frames
#'
#' @param object A keyed data frame.
#' @param ... Additional arguments (ignored).
#'
#' @return Invisibly returns a summary list.
#'
#' @export
summary.keyed_df <- function(object, ...) {
  key_cols <- get_key_cols(object)

  cli::cli_h3("Keyed Data Frame Summary")
  cli::cli_text("Dimensions: {nrow(object)} rows x {ncol(object)} columns")

  # Key info
  if (!is.null(key_cols)) {
    cli::cli_text("")
    cli::cli_text("{.strong Key columns}: {.field {paste(key_cols, collapse = ', ')}}")

    # Check key validity
    if (all(key_cols %in% names(object))) {
      key_vals <- object[key_cols]
      n_unique <- vctrs::vec_unique_count(key_vals)
      n_na <- sum(rowSums(is.na(key_vals)) > 0)

      if (n_unique == nrow(object)) {
        cli::cli_alert_success("Key is unique")
      } else {
        cli::cli_alert_warning("{nrow(object) - n_unique} duplicate key value(s)")
      }
      if (n_na > 0) {
        cli::cli_alert_warning("{n_na} row(s) with NA in key")
      }
    } else {
      missing <- setdiff(key_cols, names(object))
      cli::cli_alert_danger("Key column(s) missing: {paste(missing, collapse = ', ')}")
    }
  } else {
    cli::cli_text("{.strong Key}: none")
  }

  # ID info
  cli::cli_text("")
  if (has_id(object)) {
    ids <- object[[".id"]]
    n_na <- sum(is.na(ids))
    n_unique <- length(unique(ids[!is.na(ids)]))
    n_dups <- length(ids) - n_na - n_unique

    cli::cli_text("{.strong Row IDs}: present (.id column)")
    if (n_na == 0 && n_dups == 0) {
      cli::cli_alert_success("{n_unique} unique IDs, no issues")
    } else {
      if (n_na > 0) cli::cli_alert_warning("{n_na} missing ID(s)")
      if (n_dups > 0) cli::cli_alert_warning("{n_dups} duplicate ID(s)")
    }
  } else {
    cli::cli_text("{.strong Row IDs}: none")
  }

  # Snapshot info
  if (!is.null(attr(object, "keyed_snapshot_ref"))) {
    cli::cli_text("")
    cli::cli_text("{.strong Snapshot}: committed")
  }

  invisible(list(
    nrow = nrow(object),
    ncol = ncol(object),
    key_cols = key_cols,
    has_id = has_id(object)
  ))
}
