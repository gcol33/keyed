# Snapshot and Drift Detection -------------------------------------------------
#
# Opt-in reference snapshots for detecting drift.
# Content-addressed storage with bounded cache.
# Loss of metadata is safe and detectable.

# Internal snapshot cache (content-addressed)
.snapshot_cache <- new.env(parent = emptyenv())

#' Stamp a data frame as reference
#'
#' Stores a snapshot of the current data state, including the full data frame.
#' This enables cell-level drift reports when used with [check_drift()].
#'
#' @param .data A data frame (preferably keyed).
#' @param name Optional name for the snapshot. If NULL, derived from data.
#' @param .silent If `TRUE`, suppress cli output. Used internally by
#'   auto-stamping in [watch()]ed data frames.
#'
#' @return Invisibly returns `.data` with snapshot metadata attached.
#'
#' @details
#' Snapshots are stored in memory for the session. They are keyed by
#' content hash, so identical data shares the same snapshot.
#'
#' When data is [watch()]ed, dplyr verbs auto-stamp before executing,
#' creating an automatic safety net for drift detection.
#'
#' @examples
#' df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
#' df <- stamp(df)
#'
#' # Later, check for drift
#' df2 <- df
#' df2$x[1] <- "z"
#' check_drift(df2)
#'
#' @seealso [watch()] for automatic stamping before dplyr verbs.
#' @export
stamp <- function(.data, name = NULL, .silent = FALSE) {
  content_hash <- hash_content(.data)

  snapshot <- list(
    timestamp    = Sys.time(),
    name         = name,
    content_hash = content_hash,
    data         = .data,
    data_size    = as.numeric(object.size(.data))
  )

  store_snapshot(content_hash, snapshot)
  attr(.data, "keyed_snapshot_ref") <- content_hash

  if (!.silent) {
    cli::cli_alert_success("Snapshot committed: {substr(content_hash, 1, 8)}...")
  }

  invisible(.data)
}

#' @rdname stamp
#' @export
commit_keyed <- function(.data, name = NULL) {
  deprecate_warn("0.2.0", "commit_keyed()", "stamp()")
  stamp(.data, name = name)
}

#' Check for drift from committed snapshot
#'
#' Compares current data against its committed reference snapshot.
#' When both snapshots are keyed with the same key columns, returns a
#' cell-level diff. Otherwise falls back to structural comparison.
#'
#' @param .data A data frame with a snapshot reference.
#' @param reference Optional content hash to compare against.
#'   If NULL, uses the attached snapshot reference.
#'
#' @return A drift report (class `keyed_drift_report`), or NULL if no
#'   snapshot found.
#'
#' @examples
#' df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
#' df <- stamp(df)
#'
#' # Modify the data
#' df$x[1] <- "modified"
#' check_drift(df)
#'
#' @export
check_drift <- function(.data, reference = NULL) {
  ref_hash <- reference %||% attr(.data, "keyed_snapshot_ref")

  if (is.null(ref_hash)) {
    warn("No snapshot reference found. Use stamp() first.")
    return(NULL)
  }

  snapshot <- get_snapshot(ref_hash)
  if (is.null(snapshot)) {
    warn(c(
      "Snapshot not found in cache.",
      i = paste("Reference:", substr(ref_hash, 1, 8), "..."),
      i = "The snapshot may have been evicted or from a previous session."
    ))
    return(NULL)
  }

  old_data <- snapshot$data
  current_hash <- hash_content(.data)
  has_drift <- snapshot$content_hash != current_hash

  # Try cell-level diff if both old and current are keyed with same key cols
  cell_diff <- NULL
  old_key_cols <- get_key_cols(old_data)
  new_key_cols <- get_key_cols(.data)

  if (!is.null(old_key_cols) && !is.null(new_key_cols) &&
      identical(old_key_cols, new_key_cols) &&
      all(old_key_cols %in% names(.data))) {
    cell_diff <- diff(old_data, .data)
  }

  # Key tracking
  key_lost <- has_key(old_data) != has_key(.data)
  key_values_changed <- FALSE
  if (!is.null(old_key_cols) && has_key(.data)) {
    old_key_hash <- hash_key_values(old_data)
    new_key_hash <- hash_key_values(.data)
    key_values_changed <- !identical(old_key_hash, new_key_hash)
  }

  report <- list(
    snapshot_ref  = ref_hash,
    snapshot_time = snapshot$timestamp,
    snapshot_name = snapshot$name,
    has_drift      = has_drift,
    diff           = cell_diff,

    # Structural fields
    nrow_before    = nrow(old_data),
    nrow_after     = nrow(.data),
    nrow_changed   = nrow(old_data) != nrow(.data),
    cols_before    = names(old_data),
    cols_after     = names(.data),
    cols_added     = setdiff(names(.data), names(old_data)),
    cols_removed   = setdiff(names(old_data), names(.data)),
    content_changed = has_drift,

    # Key fields
    key_lost           = key_lost,
    key_values_changed = key_values_changed
  )

  structure(report, class = "keyed_drift_report")
}

#' @export
print.keyed_drift_report <- function(x, ...) {
  cli::cli_h3("Drift Report")
  cli::cli_text("Snapshot: {substr(x$snapshot_ref, 1, 8)}... ({format(x$snapshot_time, '%Y-%m-%d %H:%M')})")

  if (!x$has_drift) {
    cli::cli_alert_success("No drift detected")
    return(invisible(x))
  }

  cli::cli_alert_warning("Drift detected")

  if (!is.null(x$diff)) {
    # Cell-level detail via keyed_diff
    cli::cli_text("")
    print(x$diff)
  } else {
    # Fallback: structural summary
    if (x$nrow_changed) {
      delta <- x$nrow_after - x$nrow_before
      sign <- if (delta > 0) "+" else ""
      cli::cli_alert_info("Row count: {x$nrow_before} -> {x$nrow_after} ({sign}{delta})")
    }
    if (length(x$cols_added) > 0) {
      cli::cli_alert_info("Columns added: {paste(x$cols_added, collapse = ', ')}")
    }
    if (length(x$cols_removed) > 0) {
      cli::cli_alert_info("Columns removed: {paste(x$cols_removed, collapse = ', ')}")
    }
    if (x$key_lost) {
      cli::cli_alert_warning("Key lost or changed")
    } else if (x$key_values_changed) {
      cli::cli_alert_info("Key values changed")
    }
    if (x$content_changed && !x$nrow_changed &&
        length(x$cols_added) == 0 && length(x$cols_removed) == 0) {
      cli::cli_alert_info("Cell values modified")
    }
  }

  invisible(x)
}

#' Clear snapshot for a data frame
#'
#' Removes the snapshot reference from a data frame.
#'
#' @param .data A data frame.
#' @param purge If TRUE, also remove the snapshot from cache.
#'
#' @return Data frame without snapshot reference.
#'
#' @export
clear_snapshot <- function(.data, purge = FALSE) {
  ref_hash <- attr(.data, "keyed_snapshot_ref")

  if (!is.null(ref_hash) && purge) {
    remove_snapshot(ref_hash)
  }

  attr(.data, "keyed_snapshot_ref") <- NULL
  .data
}

#' List all snapshots in cache
#'
#' @return Data frame with snapshot information, including `size_mb`.
#'
#' @export
list_snapshots <- function() {
  hashes <- ls(.snapshot_cache)
  if (length(hashes) == 0) {
    return(tibble::tibble(
      hash = character(),
      name = character(),
      timestamp = as.POSIXct(character()),
      nrow = integer(),
      ncol = integer(),
      size_mb = numeric()
    ))
  }

  snapshots <- lapply(hashes, get_snapshot)
  tibble::tibble(
    hash = substr(hashes, 1, 8),
    name = vapply(snapshots, function(s) s$name %||% NA_character_, character(1)),
    timestamp = do.call(c, lapply(snapshots, function(s) s$timestamp)),
    nrow = vapply(snapshots, function(s) nrow(s$data), integer(1)),
    ncol = vapply(snapshots, function(s) ncol(s$data), integer(1)),
    size_mb = vapply(snapshots, function(s) s$data_size / 1024^2, numeric(1))
  )
}

#' Clear all snapshots from cache
#'
#' @param confirm If TRUE, require confirmation.
#'
#' @return No return value, called for side effects.
#'
#' @export
clear_all_snapshots <- function(confirm = TRUE) {
  n <- length(ls(.snapshot_cache))
  if (n == 0) {
    cli::cli_alert_info("No snapshots in cache.")
    return(invisible(NULL))
  }

  if (confirm) {
    cli::cli_alert_warning("This will remove {n} snapshot(s) from cache.")
  }

  rm(list = ls(.snapshot_cache), envir = .snapshot_cache)
  cli::cli_alert_success("Cleared {n} snapshot(s).")
  invisible(NULL)
}


# Cache management -------------------------------------------------------------

#' Maximum number of snapshots to keep in cache
#' @noRd
SNAPSHOT_CACHE_SIZE <- 20

#' Soft memory cap for snapshot cache (100 MB)
#' @noRd
SNAPSHOT_MEMORY_CAP <- 100 * 1024^2

#' Total memory used by snapshot cache
#' @noRd
cache_memory_usage <- function() {
  hashes <- ls(.snapshot_cache)
  if (length(hashes) == 0) return(0)
  sum(vapply(hashes, function(h) {
    .snapshot_cache[[h]]$data_size
  }, numeric(1)))
}

#' Store snapshot in cache with LRU eviction
#' @noRd
store_snapshot <- function(hash, snapshot) {
  # Evict by LRU when count OR memory exceeded
  while (length(ls(.snapshot_cache)) >= SNAPSHOT_CACHE_SIZE ||
         (length(ls(.snapshot_cache)) > 0 &&
          cache_memory_usage() + snapshot$data_size > SNAPSHOT_MEMORY_CAP)) {
    evict_oldest_snapshot()
    if (length(ls(.snapshot_cache)) == 0) break
  }

  .snapshot_cache[[hash]] <- snapshot
}

#' Get snapshot from cache
#' @noRd
get_snapshot <- function(hash) {
  if (exists(hash, envir = .snapshot_cache)) {
    .snapshot_cache[[hash]]
  } else {
    NULL
  }
}

#' Remove snapshot from cache
#' @noRd
remove_snapshot <- function(hash) {
  if (exists(hash, envir = .snapshot_cache)) {
    rm(list = hash, envir = .snapshot_cache)
  }
}

#' Evict oldest snapshot (LRU)
#' @noRd
evict_oldest_snapshot <- function() {
  hashes <- ls(.snapshot_cache)
  if (length(hashes) == 0) return()

  timestamps <- vapply(hashes, function(h) {
    as.numeric(.snapshot_cache[[h]]$timestamp)
  }, numeric(1))

  oldest <- hashes[which.min(timestamps)]
  rm(list = oldest, envir = .snapshot_cache)
}


# Hashing ----------------------------------------------------------------------

#' Hash full content of data frame
#' @noRd
hash_content <- function(.data) {
  # Remove keyed-specific attributes before hashing
  # so the hash is stable before and after commit/watch
  attr(.data, "keyed_snapshot_ref") <- NULL
  attr(.data, "keyed_cols") <- NULL
  attr(.data, "keyed_hash") <- NULL
  attr(.data, "keyed_watched") <- NULL
  class(.data) <- setdiff(class(.data), "keyed_df")

  digest::digest(.data, algo = "xxhash64")
}

#' Hash key column values only
#' @noRd
hash_key_values <- function(.data) {
  key_cols <- get_key_cols(.data)
  if (is.null(key_cols)) return(NULL)

  key_data <- .data[key_cols]
  digest::digest(key_data, algo = "xxhash64")
}


# Watch / Unwatch ---------------------------------------------------------------

#' Watch a keyed data frame for automatic drift detection
#'
#' Marks a keyed data frame as "watched". Watched data frames are
#' automatically stamped before each dplyr verb, so [check_drift()] always
#' reports changes from the most recent transformation step.
#'
#' @param .data A keyed data frame.
#'
#' @return Invisibly returns `.data` with watched attribute set and
#'   a baseline snapshot committed.
#'
#' @examples
#' df <- key(data.frame(id = 1:5, x = letters[1:5]), id) |> watch()
#' df2 <- df |> dplyr::filter(id > 2)
#' check_drift(df2)
#'
#' @seealso [unwatch()] to stop watching, [stamp()] for manual snapshots.
#' @export
watch <- function(.data) {
  if (!has_key(.data)) {
    abort("watch() requires keyed data. Use key() first.")
  }
  attr(.data, "keyed_watched") <- TRUE
  .data <- stamp(.data)
  invisible(.data)
}

#' Stop watching a keyed data frame
#'
#' Removes the watched attribute. Dplyr verbs will no longer auto-stamp.
#'
#' @param .data A data frame.
#'
#' @return `.data` without the watched attribute.
#'
#' @examples
#' df <- key(data.frame(id = 1:3, x = 1:3), id) |> watch()
#' df <- unwatch(df)
#'
#' @seealso [watch()]
#' @export
unwatch <- function(.data) {
  attr(.data, "keyed_watched") <- NULL
  .data
}

#' Check if a data frame is watched
#' @noRd
is_watched <- function(.data) {
  isTRUE(attr(.data, "keyed_watched"))
}
