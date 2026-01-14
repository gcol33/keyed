# Join Diagnostics -------------------------------------------------------------
#
# Pre-join diagnostics to understand cardinality before executing.
# For validated joins with cardinality enforcement, use joinspy.

#' Diagnose a join before executing
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
#' diagnose_join(x, y, by = "id", use_joinspy = FALSE)
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


# Helpers ----------------------------------------------------------------------

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
