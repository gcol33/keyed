# Snapshot and Drift Detection -------------------------------------------------
#
# Opt-in reference snapshots for detecting drift.
# Content-addressed storage with bounded cache.
# Loss of metadata is safe and detectable.

# Internal snapshot cache (content-addressed)
.snapshot_cache <- new.env(parent = emptyenv())

#' Commit a keyed data frame as reference
#'
#' Stores a hash-based snapshot of the current data state.
#' Only one active reference per data frame (identified by its content hash).
#'
#' @param .data A data frame (preferably keyed).
#' @param name Optional name for the snapshot. If NULL, derived from data.
#'
#' @return Invisibly returns `.data` with snapshot metadata attached.
#'
#' @details
#' The snapshot stores:
#' - Row count
#' - Column names and types
#' - Hash of key columns (if keyed)
#' - Hash of full content
#'
#' Snapshots are stored in memory for the session. They are keyed by
#' content hash, so identical data shares the same snapshot.
#'
#' @examples
#' df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
#' df <- commit_keyed(df)
#'
#' # Later, check for drift
#' df2 <- df
#' df2$x[1] <- "z"
#' check_drift(df2)
#'
#' @export
commit_keyed <- function(.data, name = NULL) {
  # Generate content hash
  content_hash <- hash_content(.data)

  # Create snapshot
  snapshot <- list(
    timestamp = Sys.time(),
    name = name,
    nrow = nrow(.data),
    ncol = ncol(.data),
    colnames = names(.data),
    coltypes = vapply(.data, function(x) class(x)[1], character(1)),
    key_cols = get_key_cols(.data),
    key_hash = if (has_key(.data)) hash_key_values(.data) else NULL,
    content_hash = content_hash
  )

  # Store in cache
  store_snapshot(content_hash, snapshot)

  # Attach reference to data
  attr(.data, "keyed_snapshot_ref") <- content_hash

  cli::cli_alert_success("Snapshot committed: {substr(content_hash, 1, 8)}...")

  invisible(.data)
}

#' Check for drift from committed snapshot
#'
#' Compares current data against its committed reference snapshot.
#' Returns diagnostic information about changes.
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
#' df <- commit_keyed(df)
#'
#' # Modify the data
#' df$x[1] <- "modified"
#' check_drift(df)
#'
#' @export
check_drift <- function(.data, reference = NULL) {
  ref_hash <- reference %||% attr(.data, "keyed_snapshot_ref")

  if (is.null(ref_hash)) {
    warn("No snapshot reference found. Use commit_keyed() first.")
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

  # Compare current state to snapshot
  current_hash <- hash_content(.data)
  current_key_hash <- if (has_key(.data)) hash_key_values(.data) else NULL

  report <- list(
    snapshot_ref = ref_hash,
    snapshot_time = snapshot$timestamp,
    snapshot_name = snapshot$name,

    # Row changes
    nrow_before = snapshot$nrow,
    nrow_after = nrow(.data),
    nrow_changed = snapshot$nrow != nrow(.data),

    # Column changes
    cols_before = snapshot$colnames,
    cols_after = names(.data),
    cols_added = setdiff(names(.data), snapshot$colnames),
    cols_removed = setdiff(snapshot$colnames, names(.data)),

    # Key changes
    key_before = snapshot$key_cols,
    key_after = get_key_cols(.data),
    key_lost = has_key(.data) != !is.null(snapshot$key_cols),
    key_hash_before = snapshot$key_hash,
    key_hash_after = current_key_hash,
    key_values_changed = !identical(snapshot$key_hash, current_key_hash),

    # Content changes
    content_hash_before = snapshot$content_hash,
    content_hash_after = current_hash,
    content_changed = snapshot$content_hash != current_hash,

    # Overall
    has_drift = snapshot$content_hash != current_hash
  )

  structure(report, class = "keyed_drift_report")
}

#' @export
print.keyed_drift_report <- function(x, ...) {
  cli::cli_h3("Drift Report")

  if (!x$has_drift) {
    cli::cli_alert_success("No drift detected")
    cli::cli_text("Snapshot: {substr(x$snapshot_ref, 1, 8)}... ({format(x$snapshot_time, '%Y-%m-%d %H:%M')})")
    return(invisible(x))
  }

  cli::cli_alert_warning("Drift detected")
  cli::cli_text("Snapshot: {substr(x$snapshot_ref, 1, 8)}... ({format(x$snapshot_time, '%Y-%m-%d %H:%M')})")

  # Row changes
  if (x$nrow_changed) {
    delta <- x$nrow_after - x$nrow_before
    sign <- if (delta > 0) "+" else ""
    cli::cli_alert_info("Row count: {x$nrow_before} -> {x$nrow_after} ({sign}{delta})")
  }

  # Column changes
  if (length(x$cols_added) > 0) {
    cli::cli_alert_info("Columns added: {paste(x$cols_added, collapse = ', ')}")
  }
  if (length(x$cols_removed) > 0) {
    cli::cli_alert_info("Columns removed: {paste(x$cols_removed, collapse = ', ')}")
  }

  # Key changes
  if (x$key_lost) {
    cli::cli_alert_warning("Key lost or changed")
  } else if (x$key_values_changed) {
    cli::cli_alert_info("Key values changed")
  }

  # Content hash
  if (x$content_changed && !x$nrow_changed && length(x$cols_added) == 0 && length(x$cols_removed) == 0) {
    cli::cli_alert_info("Cell values modified")
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
#' @return Data frame with snapshot information.
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
      ncol = integer()
    ))
  }

  snapshots <- lapply(hashes, get_snapshot)
  tibble::tibble(
    hash = substr(hashes, 1, 8),
    name = vapply(snapshots, function(s) s$name %||% NA_character_, character(1)),
    timestamp = do.call(c, lapply(snapshots, function(s) s$timestamp)),
    nrow = vapply(snapshots, function(s) s$nrow, integer(1)),
    ncol = vapply(snapshots, function(s) s$ncol, integer(1))
  )
}

#' Clear all snapshots from cache
#'
#' @param confirm If TRUE, require confirmation.
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
SNAPSHOT_CACHE_SIZE <- 100

#' Store snapshot in cache with LRU eviction
#' @noRd
store_snapshot <- function(hash, snapshot) {
  # Check cache size and evict if needed
  current_size <- length(ls(.snapshot_cache))
  if (current_size >= SNAPSHOT_CACHE_SIZE) {
    evict_oldest_snapshot()
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
  # so the hash is stable before and after commit
  attr(.data, "keyed_snapshot_ref") <- NULL
  attr(.data, "keyed_cols") <- NULL
  attr(.data, "keyed_hash") <- NULL
  class(.data) <- setdiff(class(.data), "keyed_df")

  # Serialize and hash
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
