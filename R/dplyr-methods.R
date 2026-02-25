# dplyr Methods for keyed_df ---------------------------------------------------
#
# These methods attempt to preserve key metadata through dplyr transformations.
# When preservation isn't possible (e.g., key columns dropped), the result
# degrades gracefully to a plain tibble with a warning.


# Snapshot state helpers -------------------------------------------------------

#' Capture snapshot state before a dplyr verb
#'
#' Auto-stamps if the data is watched, then captures the snapshot reference
#' and watched status for restoration after NextMethod().
#' @noRd
capture_snapshot_state <- function(.data) {
  if (is_watched(.data)) .data <- stamp(.data, .silent = TRUE)
  list(
    data         = .data,
    watched      = is_watched(.data),
    snapshot_ref = attr(.data, "keyed_snapshot_ref")
  )
}

#' Restore snapshot/watch attributes on dplyr verb result
#'
#' NextMethod() → as_tibble strips custom attributes. This restores them.
#' @noRd
apply_snapshot_state <- function(result, state) {
  if (!is.null(state$snapshot_ref)) {
    attr(result, "keyed_snapshot_ref") <- state$snapshot_ref
  }
  if (state$watched) attr(result, "keyed_watched") <- TRUE
  result
}


#' @importFrom dplyr dplyr_reconstruct
#' @export
dplyr_reconstruct.keyed_df <- function(data, template) {
 key_cols <- get_key_cols(template)

  if (is.null(key_cols)) {
    return(tibble::as_tibble(data))
  }

  # Check if key columns still exist
  if (!all(key_cols %in% names(data))) {
    # Silently degrade - the operation intentionally removed key columns
    return(tibble::as_tibble(data))
  }

  # Check uniqueness only if row count changed significantly
  # (avoids expensive check on simple mutate)
  if (nrow(data) != nrow(template)) {
    key_vals <- data[key_cols]
    n_unique <- vctrs::vec_unique_count(key_vals)
    if (n_unique != nrow(data)) {
      abort(c(
        "Key is no longer unique after transformation.",
        i = "Use `unkey()` first if you intend to break uniqueness."
      ))
    }
  }

  new_keyed_df(data, key_cols)
}

#' @importFrom dplyr filter
#' @export
filter.keyed_df <- function(.data, ..., .preserve = FALSE) {
  state <- capture_snapshot_state(.data)
  .data <- state$data
  key_cols <- get_key_cols(.data)
  result <- NextMethod()
  if (all(key_cols %in% names(result))) {
    result <- new_keyed_df(result, key_cols)
  } else {
    result <- tibble::as_tibble(result)
  }
  apply_snapshot_state(result, state)
}

#' @importFrom dplyr select
#' @export
select.keyed_df <- function(.data, ...) {
  state <- capture_snapshot_state(.data)
  .data <- state$data
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  if (all(key_cols %in% names(result))) {
    result <- new_keyed_df(result, key_cols)
  } else {
    dropped <- setdiff(key_cols, names(result))
    warn(c(
      "Key column(s) removed by select:",
      paste0("- ", dropped)
    ))
    result <- tibble::as_tibble(result)
  }
  apply_snapshot_state(result, state)
}

#' @importFrom dplyr mutate
#' @export
mutate.keyed_df <- function(.data, ...) {
  state <- capture_snapshot_state(.data)
  .data <- state$data
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  if (all(key_cols %in% names(result))) {
    old_keys <- .data[key_cols]
    new_keys <- result[key_cols]

    if (!identical(old_keys, new_keys)) {
      n_unique <- vctrs::vec_unique_count(new_keys)
      if (n_unique != nrow(result)) {
        abort(c(
          "Key is no longer unique after transformation.",
          i = "Use `unkey()` first if you intend to break uniqueness."
        ))
      }
    }
    result <- new_keyed_df(result, key_cols)
  } else {
    result <- tibble::as_tibble(result)
  }
  apply_snapshot_state(result, state)
}

#' @importFrom dplyr arrange
#' @export
arrange.keyed_df <- function(.data, ..., .by_group = FALSE) {
  state <- capture_snapshot_state(.data)
  .data <- state$data
  key_cols <- get_key_cols(.data)
  result <- NextMethod()
  result <- new_keyed_df(result, key_cols)
  apply_snapshot_state(result, state)
}

#' @importFrom dplyr rename
#' @export
rename.keyed_df <- function(.data, ...) {
  state <- capture_snapshot_state(.data)
  .data <- state$data
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  dots <- rlang::enquos(...)
  rename_map <- vapply(dots, rlang::as_label, character(1))
  old_names <- names(rename_map)

  new_key_cols <- key_cols
  for (i in seq_along(rename_map)) {
    old_name <- rename_map[[i]]
    new_name <- old_names[[i]]
    idx <- which(new_key_cols == old_name)
    if (length(idx) > 0) {
      new_key_cols[idx] <- new_name
    }
  }

  result <- new_keyed_df(result, new_key_cols)
  apply_snapshot_state(result, state)
}

#' @importFrom dplyr summarise summarize
#' @export
summarise.keyed_df <- function(.data, ..., .groups = NULL) {
  state <- capture_snapshot_state(.data)
  .data <- state$data
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  groups <- dplyr::group_vars(.data)

  if (length(groups) > 0 && setequal(groups, key_cols)) {
    if (all(key_cols %in% names(result))) {
      n_unique <- vctrs::vec_unique_count(result[key_cols])
      if (n_unique == nrow(result)) {
        result <- new_keyed_df(result, key_cols)
        return(apply_snapshot_state(result, state))
      }
    }
  }

  result <- tibble::as_tibble(result)
  apply_snapshot_state(result, state)
}

#' @export
summarize.keyed_df <- summarise.keyed_df

#' @importFrom dplyr slice
#' @export
slice.keyed_df <- function(.data, ..., .preserve = FALSE) {
  state <- capture_snapshot_state(.data)
  .data <- state$data
  key_cols <- get_key_cols(.data)
  result <- NextMethod()
  result <- new_keyed_df(result, key_cols)
  apply_snapshot_state(result, state)
}

#' @importFrom dplyr distinct
#' @export
distinct.keyed_df <- function(.data, ..., .keep_all = FALSE) {
  state <- capture_snapshot_state(.data)
  .data <- state$data
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  if (all(key_cols %in% names(result))) {
    n_unique <- vctrs::vec_unique_count(result[key_cols])
    if (n_unique == nrow(result)) {
      result <- new_keyed_df(result, key_cols)
      return(apply_snapshot_state(result, state))
    }
  }

  result <- tibble::as_tibble(result)
  apply_snapshot_state(result, state)
}

#' @importFrom dplyr group_by
#' @export
group_by.keyed_df <- function(.data, ..., .add = FALSE, .drop = TRUE) {
  state <- capture_snapshot_state(.data)
  .data <- state$data
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  if (all(key_cols %in% names(result))) {
    attr(result, "keyed_cols") <- key_cols
    class(result) <- unique(c("keyed_df", class(result)))
  }
  apply_snapshot_state(result, state)
}

#' @importFrom dplyr ungroup
#' @export
ungroup.keyed_df <- function(x, ...) {
  state <- capture_snapshot_state(x)
  x <- state$data
  key_cols <- get_key_cols(x)
  result <- NextMethod()

  if (all(key_cols %in% names(result))) {
    result <- new_keyed_df(result, key_cols)
  } else {
    result <- tibble::as_tibble(result)
  }
  apply_snapshot_state(result, state)
}


# Bind operations --------------------------------------------------------------

#' Bind rows of keyed data frames
#'
#' Bind keyed data frames
#'
#' Wrapper for [dplyr::bind_rows()] that attempts to preserve key metadata.
#'
#' @param ... Data frames to bind.
#' @param .id Optional column name to identify source.
#'
#' @return A keyed data frame if key is preserved and unique, otherwise tibble.
#'
#' @export
bind_keyed <- function(..., .id = NULL) {
  dfs <- list(...)

  # Get key from first keyed_df
  key_cols <- NULL
  for (df in dfs) {
    if (has_key(df)) {
      key_cols <- get_key_cols(df)
      break
    }
  }

  result <- dplyr::bind_rows(lapply(dfs, unkey), .id = .id)

  if (!is.null(key_cols) && all(key_cols %in% names(result))) {
    # Check uniqueness after bind
    n_unique <- vctrs::vec_unique_count(result[key_cols])
    if (n_unique != nrow(result)) {
      abort(c(
        "Key is not unique after binding.",
        i = "Use `unkey()` on inputs first if you intend to break uniqueness."
      ))
    }
    new_keyed_df(result, key_cols)
  } else {
    result
  }
}
