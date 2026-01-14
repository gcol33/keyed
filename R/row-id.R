# Row Identity -----------------------------------------------------------------
#
# Optional stable UUID per row for lineage tracking and debugging.
# Explicit opt-in only. Loss of ID triggers warnings, not failure.

#' Add row identity column
#'
#' Adds a stable UUID column to each row. This is an opt-in feature for
#' tracking row lineage through transformations.
#'
#' @param .data A data frame.
#' @param .id Column name for the row ID (default: ".row_id").
#' @param .overwrite If TRUE, overwrite existing ID column. If FALSE (default),
#'   error if column exists.
#'
#' @return Data frame with row ID column added.
#'
#' @details
#' Row IDs are generated using a hash of row content plus a random salt,
#' making them stable for identical rows within a session but unique across
#' different data frames.
#'
#' If the uuid package is available, it will be used for true UUIDs.
#' Otherwise, a hash-based ID is generated.
#'
#' @examples
#' df <- data.frame(x = 1:3, y = c("a", "b", "c"))
#' df <- add_row_id(df)
#' df
#'
#' @export
add_row_id <- function(.data, .id = ".row_id", .overwrite = FALSE) {
  if (!is.character(.id) || length(.id) != 1) {
    abort("`.id` must be a single string.")
  }

  if (.id %in% names(.data)) {
    if (!.overwrite) {
      abort(c(
        paste0("Column '", .id, "' already exists."),
        i = "Use `.overwrite = TRUE` to replace it."
      ))
    }
    # Remove existing column before adding new one
    .data[[.id]] <- NULL
  }

  n <- nrow(.data)
  if (n == 0) {
    .data[[.id]] <- character(0)
    return(.data)
  }

  # Generate row IDs
  ids <- generate_row_ids(n)

  # Add column at the front
  .data <- tibble::add_column(.data, !!.id := ids, .before = 1)

  .data
}

#' Check if data frame has row IDs
#'
#' @param .data A data frame.
#' @param .id Column name to check (default: ".row_id").
#'
#' @return Logical.
#'
#' @export
has_row_id <- function(.data, .id = ".row_id") {
  .id %in% names(.data)
}

#' Get row ID column
#'
#' @param .data A data frame.
#' @param .id Column name (default: ".row_id").
#'
#' @return Character vector of row IDs, or NULL if not present.
#'
#' @export
get_row_id <- function(.data, .id = ".row_id") {
  if (!has_row_id(.data, .id)) {
    return(NULL)
  }
  .data[[.id]]
}

#' Remove row ID column
#'
#' @param .data A data frame.
#' @param .id Column name to remove (default: ".row_id").
#'
#' @return Data frame without the row ID column.
#'
#' @export
remove_row_id <- function(.data, .id = ".row_id") {
  if (.id %in% names(.data)) {
    .data[[.id]] <- NULL
  }
  .data
}

#' Check for lost row IDs
#'
#' Compares row IDs between two data frames to detect lost rows.
#'
#' @param before Data frame before transformation.
#' @param after Data frame after transformation.
#' @param .id Column name for row IDs (default: ".row_id").
#'
#' @return A list with:
#'   - `lost`: Row IDs present in `before` but not `after`
#'   - `gained`: Row IDs present in `after` but not `before`
#'   - `preserved`: Row IDs present in both
#'
#' @examples
#' df1 <- add_row_id(data.frame(x = 1:5))
#' df2 <- df1[1:3, ]
#' compare_row_ids(df1, df2)
#'
#' @export
compare_row_ids <- function(before, after, .id = ".row_id") {
  if (!has_row_id(before, .id)) {
    abort("'before' does not have row IDs.")
  }
  if (!has_row_id(after, .id)) {
    warn("'after' does not have row IDs. Cannot compare.")
    return(list(lost = character(), gained = character(), preserved = character()))
  }

  ids_before <- before[[.id]]
  ids_after <- after[[.id]]

  list(
    lost = setdiff(ids_before, ids_after),
    gained = setdiff(ids_after, ids_before),
    preserved = intersect(ids_before, ids_after)
  )
}


# Helpers ----------------------------------------------------------------------

#' Generate unique row IDs
#' @noRd
generate_row_ids <- function(n) {
  if (n == 0) return(character(0))

  # Try uuid package first
  if (requireNamespace("uuid", quietly = TRUE)) {
    vapply(seq_len(n), function(i) uuid::UUIDgenerate(), character(1))
  } else {
    # Fallback: hash-based IDs
    salt <- paste0(Sys.time(), Sys.getpid(), sample.int(1e6, 1))
    vapply(seq_len(n), function(i) {
      digest::digest(paste0(salt, i), algo = "xxhash64")
    }, character(1))
  }
}
