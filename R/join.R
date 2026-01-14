# Checked Joins ----------------------------------------------------------------
#
# Wrappers around dplyr joins that validate expected cardinality and coverage.
# Fail or warn at the operation boundary, not globally.
#
# Optionally integrates with joinspy for enhanced diagnostics when available.

#' Left join with validation
#'
#' Performs a left join with optional cardinality and coverage checks.
#'
#' @param x Left data frame.
#' @param y Right data frame.
#' @param by Join specification (passed to dplyr).
#' @param expect Expected cardinality: "one-to-one", "one-to-many",
#'   "many-to-one", or NULL (no check).
#' @param coverage Minimum fraction of x keys that must match y (0 to 1).
#' @param .strict If TRUE, error on violations. If FALSE (default), warn.
#' @param ... Additional arguments passed to [dplyr::left_join()].
#'
#' @return Result of the left join.
#'
#' @examples
#' users <- data.frame(id = 1:3, name = c("A", "B", "C"))
#' orders <- data.frame(user_id = c(1, 1, 2), amount = c(100, 200, 150))
#'
#' # Check one-to-many relationship
#' left_join_checked(users, orders, by = c("id" = "user_id"), expect = "one-to-many")
#'
#' # Check coverage
#' left_join_checked(users, orders, by = c("id" = "user_id"), coverage = 0.5)
#'
#' @export
left_join_checked <- function(x, y, by = NULL, expect = NULL, coverage = NULL,
                               .strict = FALSE, ...) {
  # Pre-join validation
  if (!is.null(expect)) {
    validate_cardinality_pre(x, y, by, expect, .strict = .strict)
  }

  # Perform the join
  result <- dplyr::left_join(x, y, by = by, ...)

  # Post-join validation
  if (!is.null(expect)) {
    validate_cardinality_post(x, result, expect, .strict = .strict)
  }

  if (!is.null(coverage)) {
    validate_coverage(x, y, result, by, coverage, .strict = .strict)
  }

  result
}

#' Inner join with validation
#'
#' Performs an inner join with optional cardinality and coverage checks.
#'
#' @inheritParams left_join_checked
#'
#' @return Result of the inner join.
#'
#' @examples
#' users <- data.frame(id = 1:3, name = c("A", "B", "C"))
#' orders <- data.frame(user_id = c(1, 2), amount = c(100, 150))
#'
#' inner_join_checked(users, orders, by = c("id" = "user_id"), expect = "one-to-one")
#'
#' @export
inner_join_checked <- function(x, y, by = NULL, expect = NULL, coverage = NULL,
                                .strict = FALSE, ...) {
  if (!is.null(expect)) {
    validate_cardinality_pre(x, y, by, expect, .strict = .strict)
  }

  result <- dplyr::inner_join(x, y, by = by, ...)

  if (!is.null(expect)) {
    validate_cardinality_post(x, result, expect, .strict = .strict)
  }

  if (!is.null(coverage)) {
    validate_coverage(x, y, result, by, coverage, .strict = .strict)
  }

  result
}

#' Right join with validation
#'
#' Performs a right join with optional cardinality and coverage checks.
#'
#' @inheritParams left_join_checked
#'
#' @return Result of the right join.
#'
#' @export
right_join_checked <- function(x, y, by = NULL, expect = NULL, coverage = NULL,
                                .strict = FALSE, ...) {
  if (!is.null(expect)) {
    validate_cardinality_pre(x, y, by, expect, .strict = .strict)
  }

  result <- dplyr::right_join(x, y, by = by, ...)

  if (!is.null(expect)) {
    # For right join, we check y's rows
    validate_cardinality_post(y, result, expect, .strict = .strict)
  }

  if (!is.null(coverage)) {
    validate_coverage(x, y, result, by, coverage, .strict = .strict)
  }

  result
}

#' Full join with validation
#'
#' Performs a full join with optional cardinality and coverage checks.
#'
#' @inheritParams left_join_checked
#'
#' @return Result of the full join.
#'
#' @export
full_join_checked <- function(x, y, by = NULL, expect = NULL, coverage = NULL,
                               .strict = FALSE, ...) {
  if (!is.null(expect)) {
    validate_cardinality_pre(x, y, by, expect, .strict = .strict)
  }

  result <- dplyr::full_join(x, y, by = by, ...)

  if (!is.null(coverage)) {
    validate_coverage(x, y, result, by, coverage, .strict = .strict)
  }

  result
}


# Validation helpers -----------------------------------------------------------

#' Validate cardinality before join
#' @noRd
validate_cardinality_pre <- function(x, y, by, expect, .strict = FALSE) {
  expect <- match.arg(expect, c("one-to-one", "one-to-many", "many-to-one"))

  # Normalize by specification
  by_spec <- normalize_by(by, x, y)
  x_cols <- by_spec$x
  y_cols <- by_spec$y

  # Check uniqueness based on expected cardinality
  x_unique <- is_unique_on(x, x_cols)
  y_unique <- is_unique_on(y, y_cols)

  violations <- character()

  if (expect == "one-to-one") {
    if (!x_unique) violations <- c(violations, "x is not unique on join columns")
    if (!y_unique) violations <- c(violations, "y is not unique on join columns")
  } else if (expect == "one-to-many") {
    if (!x_unique) violations <- c(violations, "x is not unique on join columns (expected one-to-many)")
  } else if (expect == "many-to-one") {
    if (!y_unique) violations <- c(violations, "y is not unique on join columns (expected many-to-one)")
  }

  if (length(violations) > 0) {
    msg <- c(
      paste0("Cardinality assumption violated (expected: ", expect, ")."),
      i = violations
    )
    if (.strict) {
      abort(msg, class = "keyed_join_error")
    } else {
      warn(msg, class = "keyed_join_warning")
    }
  }
}

#' Validate cardinality after join (check for explosion)
#' @noRd
validate_cardinality_post <- function(original, result, expect, .strict = FALSE) {
  n_original <- nrow(original)
  n_result <- nrow(result)

  if (expect == "one-to-one" && n_result != n_original) {
    msg <- c(
      "Join explosion detected (expected one-to-one).",
      i = paste0("Original rows: ", n_original, ", Result rows: ", n_result)
    )
    if (.strict) {
      abort(msg, class = "keyed_join_error")
    } else {
      warn(msg, class = "keyed_join_warning")
    }
  }
}

#' Validate coverage after join
#' @noRd
validate_coverage <- function(x, y, result, by, threshold, .strict = FALSE) {
  if (!is.numeric(threshold) || length(threshold) != 1 ||
      threshold < 0 || threshold > 1) {
    abort("`coverage` must be a single number between 0 and 1.")
  }

  # Normalize by specification
  by_spec <- normalize_by(by, x, y)
  x_cols <- by_spec$x

  # Count how many x keys have matching y values
  n_x <- nrow(x)
  if (n_x == 0) return(invisible(NULL))

  # For left join, check how many result rows have non-NA y columns
  # Simpler: count unique x keys that got a match
  y_only_cols <- setdiff(names(y), by_spec$y)
  if (length(y_only_cols) == 0) {
    # No columns to check coverage on
    return(invisible(NULL))
  }

  # Check first y-only column for NA (indicates no match)
  check_col <- y_only_cols[1]
  if (check_col %in% names(result)) {
    n_matched <- sum(!is.na(result[[check_col]]))
    actual_coverage <- n_matched / n_x
  } else {
    # Can't determine coverage
    return(invisible(NULL))
  }

  if (actual_coverage < threshold) {
    msg <- c(
      paste0("Coverage assumption violated."),
      i = paste0("Expected: >= ", threshold * 100, "%, Actual: ",
                 sprintf("%.1f%%", actual_coverage * 100))
    )
    if (.strict) {
      abort(msg, class = "keyed_join_error")
    } else {
      warn(msg, class = "keyed_join_warning")
    }
  }
}

#' Check if data frame is unique on specified columns
#' @noRd
is_unique_on <- function(df, cols) {
  if (length(cols) == 0) return(TRUE)
  if (nrow(df) == 0) return(TRUE)

  vals <- df[cols]
  vctrs::vec_unique_count(vals) == nrow(df)
}

#' Normalize join 'by' specification
#' @noRd
normalize_by <- function(by, x, y) {
  if (is.null(by)) {
    # Natural join - find common columns
    common <- intersect(names(x), names(y))
    return(list(x = common, y = common))
  }

  if (is.character(by)) {
    if (is.null(names(by))) {
      # Simple character vector
      return(list(x = by, y = by))
    } else {
      # Named vector: c("x_col" = "y_col")
      return(list(x = names(by), y = unname(by)))
    }
  }

  # join_by() expressions - just use common approach for now
  common <- intersect(names(x), names(y))
  list(x = common, y = common)
}


# Detect join explosions -------------------------------------------------------

#' Check for potential join explosion before executing
#'
#' Analyzes join cardinality without performing the full join.
#' Useful for detecting many-to-many joins that would explode row count.
#'
#' If the joinspy package is installed, this function delegates to
#' `joinspy::join_spy()` for enhanced diagnostics including whitespace
#' detection, encoding issues, and detailed match analysis.
#'
#' @param x Left data frame.
#' @param y Right data frame.
#' @param by Join specification.
#' @param use_joinspy If TRUE (default), use joinspy for enhanced diagnostics
#'   when available. Set to FALSE to use built-in diagnostics only.
#'
#' @return A list with cardinality information, or a JoinReport object if
#'   joinspy is used.
#'
#' @examples
#' x <- data.frame(id = c(1, 1, 2), a = 1:3)
#' y <- data.frame(id = c(1, 1, 2), b = 4:6)
#' diagnose_join(x, y, by = "id")
#'
#' @seealso `joinspy::join_spy()` for enhanced diagnostics (if installed)
#'
#' @export
diagnose_join <- function(x, y, by = NULL, use_joinspy = TRUE) {
  # Use joinspy if available and requested
 if (use_joinspy && has_joinspy()) {
    return(joinspy::join_spy(x, y, by = by))
  }

  # Built-in diagnostics
  by_spec <- normalize_by(by, x, y)

  x_unique <- is_unique_on(x, by_spec$x)
  y_unique <- is_unique_on(y, by_spec$y)

  # Count duplicates
  x_dups <- count_duplicates(x, by_spec$x)
  y_dups <- count_duplicates(y, by_spec$y)

  # Estimate result size
  max_explosion <- estimate_join_size(x, y, by_spec)

  cardinality <- if (x_unique && y_unique) {
    "one-to-one"
  } else if (x_unique && !y_unique) {
    "one-to-many"
  } else if (!x_unique && y_unique) {
    "many-to-one"
  } else {
    "many-to-many"
  }

  structure(
    list(
      cardinality = cardinality,
      x_unique = x_unique,
      y_unique = y_unique,
      x_rows = nrow(x),
      y_rows = nrow(y),
      x_duplicates = x_dups,
      y_duplicates = y_dups,
      max_result_rows = max_explosion
    ),
    class = "keyed_join_diagnosis"
  )
}

#' @export
print.keyed_join_diagnosis <- function(x, ...) {
  cli::cli_h3("Join Diagnosis")
  cli::cli_text("Cardinality: {.strong {x$cardinality}}")
  cli::cli_text("x: {x$x_rows} rows, {if (x$x_unique) 'unique' else paste0(x$x_duplicates, ' duplicates')}")
  cli::cli_text("y: {x$y_rows} rows, {if (x$y_unique) 'unique' else paste0(x$y_duplicates, ' duplicates')}")
  if (x$cardinality == "many-to-many") {
    cli::cli_alert_warning("Many-to-many join may produce up to {x$max_result_rows} rows")
  }
  invisible(x)
}

#' Count duplicate key values
#' @noRd
count_duplicates <- function(df, cols) {
  if (length(cols) == 0 || nrow(df) == 0) return(0)
  vals <- df[cols]
  nrow(df) - vctrs::vec_unique_count(vals)
}

#' Estimate maximum join result size
#' @noRd
estimate_join_size <- function(x, y, by_spec) {
  if (nrow(x) == 0 || nrow(y) == 0) return(0)

  # Get key values from both sides
  x_keys <- x[by_spec$x]
  y_keys <- y[by_spec$y]

  # Count occurrences of each key
  x_counts <- as.data.frame(table(do.call(paste, c(x_keys, sep = "\x1f"))))
  y_counts <- as.data.frame(table(do.call(paste, c(y_keys, sep = "\x1f"))))

  names(x_counts) <- c("key", "x_n")
  names(y_counts) <- c("key", "y_n")

  # Join counts
  merged <- merge(x_counts, y_counts, by = "key", all = FALSE)
  if (nrow(merged) == 0) return(0)

  sum(as.numeric(merged$x_n) * as.numeric(merged$y_n))
}


# joinspy integration ----------------------------------------------------------

#' Check if joinspy is available
#' @noRd
has_joinspy <- function() {
  requireNamespace("joinspy", quietly = TRUE)
}

#' Spy on a join operation
#'
#' Wrapper around `joinspy::join_spy()` for comprehensive pre-join diagnostics.
#' If joinspy is not installed, falls back to [diagnose_join()].
#'
#' @inheritParams diagnose_join
#'
#' @return A JoinReport object (if joinspy available) or keyed_join_diagnosis.
#'
#' @examples
#' x <- data.frame(id = 1:3, a = 1:3)
#' y <- data.frame(id = 2:4, b = 1:3)
#' spy_join(x, y, by = "id")
#'
#' @export
spy_join <- function(x, y, by = NULL) {
  if (has_joinspy()) {
    joinspy::join_spy(x, y, by = by)
  } else {
    inform(c(
      "Install joinspy for enhanced diagnostics:",
      i = 'install.packages("joinspy")'
    ))
    diagnose_join(x, y, by = by, use_joinspy = FALSE)
  }
}

#' Explain a join result
#'
#' Wrapper around `joinspy::join_explain()` to understand what happened
#' during a join. If joinspy is not installed, provides basic row count info.
#'
#' @param before Data frame before join (the left table).
#' @param after Data frame after join (the result).
#' @param by Join columns used.
#'
#' @return A join explanation object.
#'
#' @examples
#' x <- data.frame(id = 1:3, a = 1:3)
#' y <- data.frame(id = c(1, 1, 2), b = 1:3)
#' result <- dplyr::left_join(x, y, by = "id")
#' explain_join(x, result, by = "id")
#'
#' @export
explain_join <- function(before, after, by = NULL) {
  if (has_joinspy()) {
    joinspy::join_explain(before, after, by = by)
  } else {
    # Basic explanation without joinspy
    n_before <- nrow(before)
    n_after <- nrow(after)
    ratio <- n_after / n_before

    cli::cli_h3("Join Explanation")
    cli::cli_text("Rows before: {n_before}")
    cli::cli_text("Rows after: {n_after}")

    if (ratio > 1) {
      cli::cli_alert_warning("Row multiplication: {sprintf('%.1fx', ratio)}")
    } else if (ratio < 1) {
      cli::cli_alert_info("Rows reduced to {sprintf('%.1f%%', ratio * 100)}")
    } else {
      cli::cli_alert_success("Row count preserved")
    }

    inform(c(
      "Install joinspy for detailed explanation:",
      i = 'install.packages("joinspy")'
    ))

    invisible(list(
      n_before = n_before,
      n_after = n_after,
      ratio = ratio
    ))
  }
}

#' Check key quality
#'
#' Wrapper around `joinspy::key_check()` for quick key quality assessment.
#' If joinspy is not installed, checks basic uniqueness and NA counts.
#'
#' @param .data A data frame.
#' @param ... Column names to check as keys.
#'
#' @return Key quality report.
#'
#' @examples
#' df <- data.frame(id = c(1, 1, 2, NA), x = 1:4)
#' check_key(df, id)
#'
#' @export
check_key <- function(.data, ...) {
  cols <- key_cols_from_dots(.data, ...)

  if (length(cols) == 0) {
    abort("At least one column must be specified.")
  }

  if (has_joinspy()) {
    joinspy::key_check(.data, by = cols)
  } else {
    # Basic key check without joinspy
    n_rows <- nrow(.data)
    key_vals <- .data[cols]
    n_unique <- vctrs::vec_unique_count(key_vals)
    n_na <- sum(rowSums(is.na(key_vals)) > 0)
    n_dups <- n_rows - n_unique

    cli::cli_h3("Key Check: {paste(cols, collapse = ', ')}")
    cli::cli_text("Rows: {n_rows}")
    cli::cli_text("Unique keys: {n_unique}")

    if (n_dups > 0) {
      cli::cli_alert_warning("{n_dups} duplicate key(s)")
    } else {
      cli::cli_alert_success("All keys unique")
    }

    if (n_na > 0) {
      cli::cli_alert_warning("{n_na} row(s) with NA in key")
    }

    invisible(list(
      columns = cols,
      n_rows = n_rows,
      n_unique = n_unique,
      n_duplicates = n_dups,
      n_na = n_na,
      is_unique = n_dups == 0
    ))
  }
}
