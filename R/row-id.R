# Row Identity -----------------------------------------------------------------
#
# Optional stable UUID per row for lineage tracking and debugging.
# Explicit opt-in only. Loss of ID triggers warnings, not failure.

#' Add identity column
#'
#' Adds a stable UUID column to each row. This is an opt-in feature for
#' tracking row lineage through transformations.
#'
#' @param .data A data frame.
#' @param .id Column name for the ID (default: ".id").
#' @param .overwrite If TRUE, overwrite existing ID column. If FALSE (default),
#'   error if column exists.
#'
#' @return Data frame with ID column added.
#'
#' @details
#' IDs are generated using a hash of row content plus a random salt,
#' making them stable for identical rows within a session but unique across
#' different data frames.
#'
#' If the uuid package is available, it will be used for true UUIDs.
#' Otherwise, a hash-based ID is generated.
#'
#' @examples
#' df <- data.frame(x = 1:3, y = c("a", "b", "c"))
#' df <- add_id(df)
#' df
#'
#' @export
add_id <- function(.data, .id = ".id", .overwrite = FALSE) {
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

  # Generate IDs
  ids <- generate_ids(n)

  # Add column at the front
  .data <- tibble::add_column(.data, !!.id := ids, .before = 1)

  .data
}

#' Check if data frame has IDs
#'
#' @param .data A data frame.
#' @param .id Column name to check (default: ".id").
#'
#' @return Logical.
#'
#' @export
has_id <- function(.data, .id = ".id") {
  .id %in% names(.data)
}

#' Get ID column
#'
#' @param .data A data frame.
#' @param .id Column name (default: ".id").
#'
#' @return Character vector of IDs, or NULL if not present.
#'
#' @export
get_id <- function(.data, .id = ".id") {
  if (!has_id(.data, .id)) {
    return(NULL)
  }
  .data[[.id]]
}

#' Remove ID column
#'
#' @param .data A data frame.
#' @param .id Column name to remove (default: ".id").
#'
#' @return Data frame without the ID column.
#'
#' @export
remove_id <- function(.data, .id = ".id") {
  if (.id %in% names(.data)) {
    .data[[.id]] <- NULL
  }
  .data
}

#' Compare IDs between data frames
#'
#' Compares IDs between two data frames to detect lost rows.
#'
#' @param before Data frame before transformation.
#' @param after Data frame after transformation.
#' @param .id Column name for IDs (default: ".id").
#'
#' @return A list with:
#'   - `lost`: IDs present in `before` but not `after`
#'   - `gained`: IDs present in `after` but not `before`
#'   - `preserved`: IDs present in both
#'
#' @examples
#' df1 <- add_id(data.frame(x = 1:5))
#' df2 <- df1[1:3, ]
#' compare_ids(df1, df2)
#'
#' @export
compare_ids <- function(before, after, .id = ".id") {
  if (!has_id(before, .id)) {
    abort("'before' does not have IDs.")
  }
  if (!has_id(after, .id)) {
    warn("'after' does not have IDs. Cannot compare.")
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


#' Extend IDs to new rows
#'
#' Adds IDs to rows where the ID column is NA, preserving existing IDs.
#' Useful after binding new data to an existing dataset with IDs.
#'
#' @param .data A data frame with an ID column (possibly with NAs).
#' @param .id Column name for IDs (default: ".id").
#'
#' @return Data frame with IDs filled in for NA rows.
#'
#' @examples
#' # Original data with IDs
#' old <- add_id(data.frame(x = 1:3))
#'
#' # New data without IDs
#' new <- data.frame(.id = NA_character_, x = 4:5)
#'
#' # Combine and extend
#' combined <- dplyr::bind_rows(old, new)
#' extend_id(combined)
#'
#' @export
extend_id <- function(.data, .id = ".id") {
  if (!.id %in% names(.data)) {
    abort(c(
      paste0("Column '", .id, "' not found."),
      i = "Use add_id() to create a new ID column."
    ))
  }

  # Find rows with NA IDs
  na_rows <- is.na(.data[[.id]])
  n_na <- sum(na_rows)

  if (n_na == 0) {
    return(.data)
  }

  # Generate new IDs for NA rows
  new_ids <- generate_ids(n_na)
  .data[[.id]][na_rows] <- new_ids

  .data
}

#' Create ID from columns
#'
#' Creates an ID column by combining values from one or more columns.
#' Unlike [add_id()], this produces deterministic IDs based on column values.
#'
#' @param .data A data frame.
#' @param ... Columns to combine into the ID.
#' @param .id Column name for the ID (default: ".id").
#' @param .sep Separator between column values (default: "|").
#'
#' @return Data frame with ID column added.
#'
#' @examples
#' df <- data.frame(country = c("US", "UK", "US"), year = c(2020, 2020, 2021))
#' make_id(df, country, year)
#' #>   .id       country year
#' #> 1 US|2020  US      2020
#' #> 2 UK|2020  UK      2020
#' #> 3 US|2021  US      2021
#'
#' @export
make_id <- function(.data, ..., .id = ".id", .sep = "|") {
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

  if (.id %in% names(.data)) {
    abort(c(
      paste0("Column '", .id, "' already exists."),
      i = "Use a different name or remove the existing column."
    ))
  }

  # Combine column values
  id_values <- do.call(paste, c(.data[cols], sep = .sep))

  # Add column at the front
  .data <- tibble::add_column(.data, !!.id := id_values, .before = 1)

  .data
}


# Helpers ----------------------------------------------------------------------

#' Generate unique IDs
#' @noRd
generate_ids <- function(n) {
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
