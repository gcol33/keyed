# Value-Level Diff ---------------------------------------------------------------
#
# Row-level and cell-level comparison between two keyed data frames.
# Uses key columns to align rows, then compares cell values.

#' Diff two keyed data frames
#'
#' Compares two data frames row-by-row using the key from `x` to align rows.
#' Identifies added, removed, and modified rows, with cell-level detail for
#' modifications.
#'
#' @param x A keyed data frame (the "old" or "reference" state).
#' @param y A data frame (the "new" state). Must contain the key columns from `x`.
#' @param ... Ignored (present for S3 compatibility with [base::diff()]).
#'
#' @return A `keyed_diff` object with fields:
#'   - `key_cols`: character vector of key column names
#'   - `n_removed`, `n_added`, `n_modified`, `n_unchanged`: counts
#'   - `removed`: data frame of rows in `x` not in `y`
#'   - `added`: data frame of rows in `y` not in `x`
#'   - `changes`: named list of per-column change tibbles
#'     (each with key columns, `old`, and `new`)
#'   - `cols_only_x`, `cols_only_y`: columns present in only one side
#'
#' @examples
#' old <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
#' new <- data.frame(id = 2:4, x = c("B", "c", "d"))
#' diff(old, new)
#'
#' @export
diff.keyed_df <- function(x, y, ...) {
  # --- validation ---
  key_cols <- get_key_cols(x)
  if (is.null(key_cols)) {
    abort("x must be keyed. Use key() first.")
  }
  if (!is.data.frame(y)) {
    abort(sprintf("y must be a data frame, got %s.", class(y)[1]))
  }
  missing_in_y <- setdiff(key_cols, names(y))
  if (length(missing_in_y) > 0) {
    abort(sprintf(
      "Key column(s) not found in y: %s.",
      paste(missing_in_y, collapse = ", ")
    ))
  }

  # --- extract keys ---
  keys_x <- x[key_cols]
  keys_y <- y[key_cols]

  # --- classify rows ---
  x_in_y <- vctrs::vec_in(keys_x, keys_y)
  y_in_x <- vctrs::vec_in(keys_y, keys_x)

  removed <- x[!x_in_y, , drop = FALSE]
  added   <- y[!y_in_x, , drop = FALSE]

  # --- common rows: cell-level comparison ---
  common_cols <- intersect(names(x), names(y))
  value_cols  <- setdiff(common_cols, key_cols)

  # Match rows by key
  match_idx <- vctrs::vec_match(keys_x[x_in_y, , drop = FALSE], keys_y)
  x_common <- x[x_in_y, , drop = FALSE]
  y_common <- y[match_idx, , drop = FALSE]

  changes <- list()
  n_modified <- 0L

  if (nrow(x_common) > 0 && length(value_cols) > 0) {
    # Build a logical matrix: TRUE where cells differ (NA-safe)
    diff_matrix <- vapply(value_cols, function(col) {
      old_val <- x_common[[col]]
      new_val <- y_common[[col]]
      # NA-safe: both NA = same, one NA = different
      !( (is.na(old_val) & is.na(new_val)) | (!is.na(old_val) & !is.na(new_val) & old_val == new_val) )
    }, logical(nrow(x_common)))

    if (is.null(dim(diff_matrix))) {
      # Single value_col produces a vector, not a matrix
      diff_matrix <- matrix(diff_matrix, ncol = 1)
      colnames(diff_matrix) <- value_cols
    }

    # Per-column change tibbles
    for (col in value_cols) {
      changed <- diff_matrix[, col]
      if (any(changed)) {
        key_part <- x_common[changed, key_cols, drop = FALSE]
        change_tbl <- tibble::tibble(
          !!!key_part,
          old = x_common[[col]][changed],
          new = y_common[[col]][changed]
        )
        changes[[col]] <- change_tbl
      }
    }

    # Count rows where ANY cell changed
    n_modified <- sum(rowSums(diff_matrix) > 0)
  }

  n_unchanged <- sum(x_in_y) - n_modified

  result <- list(
    key_cols     = key_cols,
    n_removed    = nrow(removed),
    n_added      = nrow(added),
    n_modified   = n_modified,
    n_unchanged  = n_unchanged,
    removed      = removed,
    added        = added,
    changes      = changes,
    cols_only_x  = setdiff(names(x), names(y)),
    cols_only_y  = setdiff(names(y), names(x))
  )

  structure(result, class = "keyed_diff")
}

#' @export
print.keyed_diff <- function(x, ...) {
  cli::cli_h3("Value Diff")
  cli::cli_text("Key: {.field {paste(x$key_cols, collapse = ', ')}}")
  cli::cli_text("")

  total <- x$n_removed + x$n_added + x$n_modified + x$n_unchanged
  if (total == 0 && x$n_added == 0) {
    cli::cli_alert_info("Both data frames are empty.")
    return(invisible(x))
  }

  if (x$n_removed == 0 && x$n_added == 0 && x$n_modified == 0 &&
      length(x$cols_only_x) == 0 && length(x$cols_only_y) == 0) {
    cli::cli_alert_success("No differences")
    return(invisible(x))
  }

  # Row-level summary
  if (x$n_removed > 0) {
    cli::cli_alert_warning("Removed: {x$n_removed} row(s)")
  }

  if (x$n_added > 0) {
    cli::cli_alert_info("Added: {x$n_added} row(s)")
  }

  if (x$n_modified > 0) {
    cli::cli_alert_warning("Modified: {x$n_modified} row(s)")
    for (col in names(x$changes)) {
      n <- nrow(x$changes[[col]])
      cli::cli_text("
  {.field {col}}: {n} change(s)")
    }
  }

  if (x$n_unchanged > 0) {
    cli::cli_text("Unchanged: {x$n_unchanged} row(s)")
  }

  # Column-level
  if (length(x$cols_only_x) > 0) {
    cli::cli_alert_info("Columns only in x: {paste(x$cols_only_x, collapse = ', ')}")
  }
  if (length(x$cols_only_y) > 0) {
    cli::cli_alert_info("Columns only in y: {paste(x$cols_only_y, collapse = ', ')}")
  }

  invisible(x)
}
