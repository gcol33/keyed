# dplyr Methods for keyed_df ---------------------------------------------------
#
# These methods attempt to preserve key metadata through dplyr transformations.
# When preservation isn't possible (e.g., key columns dropped), the result
# degrades gracefully to a plain tibble with a warning.

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
      # Uniqueness lost - degrade silently
      return(tibble::as_tibble(data))
    }
  }

  new_keyed_df(data, key_cols)
}

#' @importFrom dplyr filter
#' @export
filter.keyed_df <- function(.data, ..., .preserve = FALSE) {
  key_cols <- get_key_cols(.data)
  result <- NextMethod()
  # filter preserves uniqueness, so just re-attach
  if (all(key_cols %in% names(result))) {
    new_keyed_df(result, key_cols)
  } else {
    tibble::as_tibble(result)
  }
}

#' @importFrom dplyr select
#' @export
select.keyed_df <- function(.data, ...) {
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  # Check if all key columns survived
  if (all(key_cols %in% names(result))) {
    new_keyed_df(result, key_cols)
  } else {
    # Key columns were dropped - warn and degrade
    dropped <- setdiff(key_cols, names(result))
    warn(c(
      "Key column(s) removed by select:",
      paste0("- ", dropped)
    ))
    tibble::as_tibble(result)
  }
}

#' @importFrom dplyr mutate
#' @export
mutate.keyed_df <- function(.data, ...) {
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  # Check if key columns were modified
  if (all(key_cols %in% names(result))) {
    # Check if key values changed
    old_keys <- .data[key_cols]
    new_keys <- result[key_cols]

    if (!identical(old_keys, new_keys)) {
      # Key was modified - validate uniqueness
      n_unique <- vctrs::vec_unique_count(new_keys)
      if (n_unique != nrow(result)) {
        warn("Key modified and is no longer unique.")
        return(tibble::as_tibble(result))
      }
    }
    new_keyed_df(result, key_cols)
  } else {
    tibble::as_tibble(result)
  }
}

#' @importFrom dplyr arrange
#' @export
arrange.keyed_df <- function(.data, ..., .by_group = FALSE) {
  key_cols <- get_key_cols(.data)
  result <- NextMethod()
  new_keyed_df(result, key_cols)
}

#' @importFrom dplyr rename
#' @export
rename.keyed_df <- function(.data, ...) {
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  # Update key column names if they were renamed
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

  new_keyed_df(result, new_key_cols)
}

#' @importFrom dplyr summarise summarize
#' @export
summarise.keyed_df <- function(.data, ..., .groups = NULL) {
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  # summarise typically destroys row identity - degrade to tibble
  # unless grouping columns match the key exactly
  groups <- dplyr::group_vars(.data)

  if (length(groups) > 0 && setequal(groups, key_cols)) {
    # Grouped by key columns - result may still be keyed
    if (all(key_cols %in% names(result))) {
      n_unique <- vctrs::vec_unique_count(result[key_cols])
      if (n_unique == nrow(result)) {
        return(new_keyed_df(result, key_cols))
      }
    }
  }

  tibble::as_tibble(result)
}

#' @export
summarize.keyed_df <- summarise.keyed_df

#' @importFrom dplyr slice
#' @export
slice.keyed_df <- function(.data, ..., .preserve = FALSE) {
  key_cols <- get_key_cols(.data)
  result <- NextMethod()
  # slice preserves uniqueness
  new_keyed_df(result, key_cols)
}

#' @importFrom dplyr distinct
#' @export
distinct.keyed_df <- function(.data, ..., .keep_all = FALSE) {
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  if (all(key_cols %in% names(result))) {
    n_unique <- vctrs::vec_unique_count(result[key_cols])
    if (n_unique == nrow(result)) {
      return(new_keyed_df(result, key_cols))
    }
  }

  tibble::as_tibble(result)
}

#' @importFrom dplyr group_by
#' @export
group_by.keyed_df <- function(.data, ..., .add = FALSE, .drop = TRUE) {
  key_cols <- get_key_cols(.data)
  result <- NextMethod()

  # Preserve keyed_df class alongside grouped_df
  if (all(key_cols %in% names(result))) {
    attr(result, "keyed_cols") <- key_cols
    class(result) <- unique(c("keyed_df", class(result)))
  }
  result
}

#' @importFrom dplyr ungroup
#' @export
ungroup.keyed_df <- function(x, ...) {
  key_cols <- get_key_cols(x)
  result <- NextMethod()

  if (all(key_cols %in% names(result))) {
    new_keyed_df(result, key_cols)
  } else {
    tibble::as_tibble(result)
  }
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
      warn("Key is not unique after bind_rows.")
      return(result)
    }
    new_keyed_df(result, key_cols)
  } else {
    result
  }
}
