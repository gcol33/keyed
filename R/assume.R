# Assumption Checks ------------------------------------------------------------
#
# Executable checks that validate assumptions about data at a specific point.
# No persistence, no metadata illusion - just explicit verification.

#' Assert that columns are unique
#'
#' Checks that the combination of specified columns has unique values.
#' This is a point-in-time assertion that either passes silently or fails.
#'
#' @param .data A data frame.
#' @param ... Column names (unquoted) to check for uniqueness.
#' @param .strict If `TRUE`, error on failure. If `FALSE` (default), warn.
#'
#' @return Invisibly returns `.data` (for piping).
#'
#' @examples
#' df <- data.frame(id = 1:3, x = c("a", "b", "c"))
#' assume_unique(df, id)
#'
#' # Fails with warning
#' df2 <- data.frame(id = c(1, 1, 2), x = c("a", "b", "c"))
#' assume_unique(df2, id)
#'
#' @export
assume_unique <- function(.data, ..., .strict = FALSE) {
  cols <- key_cols_from_dots(.data, ...)

  if (length(cols) == 0) {
    abort("At least one column must be specified.")
  }

  missing <- setdiff(cols, names(.data))
  if (length(missing) > 0) {
    abort(c(
      "Column(s) not found:",
      paste0("- ", missing)
    ))
  }

  vals <- .data[cols]
  n_rows <- nrow(.data)
  n_unique <- vctrs::vec_unique_count(vals)

  if (n_unique != n_rows) {
    n_dups <- n_rows - n_unique
    msg <- c(
      "Uniqueness assumption violated.",
      i = paste0(n_dups, " duplicate value(s) in: ", paste(cols, collapse = ", ")),
      i = paste0("Rows: ", n_rows, ", Unique: ", n_unique)
    )
    if (.strict) {
      abort(msg, class = "keyed_assumption_error")
    } else {
      warn(msg, class = "keyed_assumption_warning")
    }
  }

  invisible(.data)
}

#' Assert that columns have no missing values
#'
#' Checks that specified columns contain no NA values.
#'
#' @param .data A data frame.
#' @param ... Column names (unquoted) to check. If empty, checks all columns.
#' @param .strict If `TRUE`, error on failure. If `FALSE` (default), warn.
#'
#' @return Invisibly returns `.data` (for piping).
#'
#' @examples
#' df <- data.frame(id = 1:3, x = c("a", NA, "c"))
#' assume_no_na(df, id)
#' assume_no_na(df, x)  # warns
#'
#' @export
assume_no_na <- function(.data, ..., .strict = FALSE) {
  cols <- key_cols_from_dots(.data, ...)

  if (length(cols) == 0) {
    cols <- names(.data)
  }

  missing <- setdiff(cols, names(.data))
  if (length(missing) > 0) {
    abort(c(
      "Column(s) not found:",
      paste0("- ", missing)
    ))
  }

  # Check each column for NAs
  na_cols <- character()
  na_counts <- integer()

  for (col in cols) {
    n_na <- sum(is.na(.data[[col]]))
    if (n_na > 0) {
      na_cols <- c(na_cols, col)
      na_counts <- c(na_counts, n_na)
    }
  }

  if (length(na_cols) > 0) {
    details <- paste0(na_cols, " (", na_counts, " NA", ifelse(na_counts > 1, "s", ""), ")")
    msg <- c(
      "No-NA assumption violated.",
      i = paste("Columns with NA values:", paste(details, collapse = ", "))
    )
    if (.strict) {
      abort(msg, class = "keyed_assumption_error")
    } else {
      warn(msg, class = "keyed_assumption_warning")
    }
  }

  invisible(.data)
}

#' Assert that data is complete (no missing values anywhere)
#'
#' Checks that all columns have no NA values.
#'
#' @param .data A data frame.
#' @param .strict If `TRUE`, error on failure. If `FALSE` (default), warn.
#'
#' @return Invisibly returns `.data` (for piping).
#'
#' @export
assume_complete <- function(.data, .strict = FALSE) {
  assume_no_na(.data, .strict = .strict)
}

#' Assert minimum coverage of values
#'
#' Checks that the fraction of non-NA values meets a threshold.
#' Useful after joins to verify expected coverage.
#'
#' @param .data A data frame.
#' @param threshold Minimum fraction of non-NA values (0 to 1).
#' @param ... Column names (unquoted) to check. If empty, checks all columns.
#' @param .strict If `TRUE`, error on failure. If `FALSE` (default), warn.
#'
#' @return Invisibly returns `.data` (for piping).
#'
#' @examples
#' df <- data.frame(id = 1:10, x = c(1:8, NA, NA))
#' assume_coverage(df, 0.8, x)
#' assume_coverage(df, 0.9, x)  # warns (only 80% coverage)
#'
#' @export
assume_coverage <- function(.data, threshold, ..., .strict = FALSE) {
  if (!is.numeric(threshold) || length(threshold) != 1 ||
      threshold < 0 || threshold > 1) {
    abort("`threshold` must be a single number between 0 and 1.")
  }

  cols <- key_cols_from_dots(.data, ...)

  if (length(cols) == 0) {
    cols <- names(.data)
  }

  missing <- setdiff(cols, names(.data))
  if (length(missing) > 0) {
    abort(c(
      "Column(s) not found:",
      paste0("- ", missing)
    ))
  }

  n_rows <- nrow(.data)
  if (n_rows == 0) {
    # Empty data frame trivially satisfies any coverage threshold
    return(invisible(.data))
  }

  # Check coverage for each column
  low_coverage_cols <- character()
  coverages <- numeric()

  for (col in cols) {
    n_non_na <- sum(!is.na(.data[[col]]))
    coverage <- n_non_na / n_rows
    if (coverage < threshold) {
      low_coverage_cols <- c(low_coverage_cols, col)
      coverages <- c(coverages, coverage)
    }
  }

  if (length(low_coverage_cols) > 0) {
    details <- paste0(
      low_coverage_cols,
      " (", sprintf("%.1f%%", coverages * 100), ")"
    )
    msg <- c(
      paste0("Coverage assumption violated (threshold: ", threshold * 100, "%)."),
      i = paste("Columns below threshold:", paste(details, collapse = ", "))
    )
    if (.strict) {
      abort(msg, class = "keyed_assumption_error")
    } else {
      warn(msg, class = "keyed_assumption_warning")
    }
  }

  invisible(.data)
}

#' Assert row count within expected range
#'
#' Checks that the number of rows is within an expected range.
#' Useful for sanity checks after filtering or joins.
#'
#' @param .data A data frame.
#' @param min Minimum expected rows (inclusive). Default 1.
#' @param max Maximum expected rows (inclusive). Default Inf.
#' @param expected Exact expected row count. If provided, overrides min/max.
#' @param .strict If `TRUE`, error on failure. If `FALSE` (default), warn.
#'
#' @return Invisibly returns `.data` (for piping).
#'
#' @examples
#' df <- data.frame(id = 1:100)
#' assume_nrow(df, min = 50, max = 200)
#' assume_nrow(df, expected = 100)
#'
#' @export
assume_nrow <- function(.data, min = 1, max = Inf, expected = NULL, .strict = FALSE) {
 n <- nrow(.data)

  if (!is.null(expected)) {
    if (n != expected) {
      msg <- c(
        "Row count assumption violated.",
        i = paste0("Expected: ", expected, ", Actual: ", n)
      )
      if (.strict) {
        abort(msg, class = "keyed_assumption_error")
      } else {
        warn(msg, class = "keyed_assumption_warning")
      }
    }
  } else {
    if (n < min || n > max) {
      range_str <- if (is.infinite(max)) {
        paste0(">= ", min)
      } else if (min == 0) {
        paste0("<= ", max)
      } else {
        paste0(min, " to ", max)
      }
      msg <- c(
        "Row count assumption violated.",
        i = paste0("Expected: ", range_str, ", Actual: ", n)
      )
      if (.strict) {
        abort(msg, class = "keyed_assumption_error")
      } else {
        warn(msg, class = "keyed_assumption_warning")
      }
    }
  }

  invisible(.data)
}
