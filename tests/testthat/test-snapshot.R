test_that("stamp creates snapshot", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)

  # Clear any existing snapshots
  keyed:::clear_all_snapshots(confirm = FALSE)

  result <- stamp(df)

  expect_true(!is.null(attr(result, "keyed_snapshot_ref")))
  expect_equal(nrow(list_snapshots()), 1)
})

test_that("check_drift detects no change", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- stamp(df)
  report <- check_drift(df)

  expect_false(report$has_drift)
})

test_that("check_drift detects content changes", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- stamp(df)
  df$x[1] <- 999
  report <- check_drift(df)

  expect_true(report$has_drift)
  expect_true(report$content_changed)
})

test_that("check_drift detects row count changes", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- stamp(df)
  df <- df[1:2, ]
  report <- check_drift(df)

  expect_true(report$has_drift)
  expect_true(report$nrow_changed)
  expect_equal(report$nrow_before, 3)
  expect_equal(report$nrow_after, 2)
})

test_that("check_drift detects column changes", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- stamp(df)
  df$y <- 4:6
  report <- check_drift(df)

  expect_true(report$has_drift)
  expect_equal(report$cols_added, "y")
})

test_that("clear_snapshot removes reference", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- stamp(df)
  df <- clear_snapshot(df)

  expect_null(attr(df, "keyed_snapshot_ref"))
})

test_that("check_drift warns when no snapshot", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_warning(check_drift(df), "No snapshot reference found")
})

test_that("list_snapshots returns empty tibble when no snapshots", {
  keyed:::clear_all_snapshots(confirm = FALSE)
  result <- list_snapshots()

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_true("hash" %in% names(result))
})

test_that("list_snapshots returns snapshot info", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  stamp(df, name = "test_snap")

  result <- list_snapshots()
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "test_snap")
})

test_that("clear_all_snapshots with empty cache", {
  keyed:::clear_all_snapshots(confirm = FALSE)
  expect_message(clear_all_snapshots(confirm = FALSE), "No snapshots")
})

test_that("clear_all_snapshots shows warning with confirm", {
  keyed:::clear_all_snapshots(confirm = FALSE)
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  stamp(df)

  expect_message(clear_all_snapshots(confirm = TRUE), "remove")
})

test_that("clear_snapshot with purge removes from cache", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df)
  ref <- attr(df, "keyed_snapshot_ref")

  df <- clear_snapshot(df, purge = TRUE)
  expect_null(keyed:::get_snapshot(ref))
})

test_that("check_drift warns when snapshot not in cache", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df)

  # Manually clear cache to simulate eviction
  keyed:::clear_all_snapshots(confirm = FALSE)

  expect_warning(report <- check_drift(df), "Snapshot not found")
  expect_null(report)
})

test_that("print.keyed_drift_report shows no drift", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df)
  report <- check_drift(df)

  expect_false(report$has_drift)
  expect_invisible(print(report))
})

test_that("print.keyed_drift_report shows drift details", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df)
  df$x[1] <- 999
  df$y <- 4:6
  report <- check_drift(df)

  expect_true(report$has_drift)
  expect_equal(report$cols_added, "y")
  expect_invisible(print(report))
})

test_that("print.keyed_drift_report shows row changes", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df)
  ref <- attr(df, "keyed_snapshot_ref")

  # Add a row manually to preserve snapshot ref
  df <- rbind(df, data.frame(id = 4, x = 4))
  attr(df, "keyed_snapshot_ref") <- ref

  report <- check_drift(df)

  expect_true(report$nrow_changed)
  expect_invisible(print(report))
})

test_that("print.keyed_drift_report shows column removal", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3, y = 4:6), id)
  df <- stamp(df)
  df$y <- NULL
  report <- check_drift(df)

  expect_equal(report$cols_removed, "y")
  expect_invisible(print(report))
})

test_that("print.keyed_drift_report shows key loss", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df)
  df <- unkey(df)
  report <- check_drift(df)

  expect_true(report$key_lost)
  expect_invisible(print(report))
})

test_that("print.keyed_drift_report shows cell value changes", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df)
  df$x[1] <- 999
  report <- check_drift(df)

  # Cell values changed without row/column changes
  expect_true(report$content_changed)
  expect_false(report$nrow_changed)
  expect_equal(length(report$cols_added), 0)
})

test_that("stamp with name parameter", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df, name = "my_snapshot")

  snaps <- list_snapshots()
  expect_equal(snaps$name, "my_snapshot")
})

test_that("check_drift detects key value changes", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df)
  df$id[1] <- 10
  report <- check_drift(df)

  expect_true(report$key_values_changed)
})

test_that("commit_keyed() is deprecated in favour of stamp()", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  lifecycle::expect_deprecated(
    result <- commit_keyed(df)
  )
  expect_true(!is.null(attr(result, "keyed_snapshot_ref")))
})

# New tests for data-storing snapshots -----------------------------------------

test_that("stamp stores actual data in snapshot", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  result <- stamp(df)
  ref <- attr(result, "keyed_snapshot_ref")
  snap <- keyed:::get_snapshot(ref)

  expect_true(!is.null(snap$data))
  expect_identical(snap$data, df)
  expect_true(snap$data_size > 0)
})

test_that("check_drift returns cell-level diff when keyed", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df <- stamp(df)
  df$x[2] <- "B"
  report <- check_drift(df)

  expect_true(report$has_drift)
  expect_s3_class(report$diff, "keyed_diff")
  expect_equal(report$diff$n_modified, 1)
  expect_equal(report$diff$changes$x$old, "b")
  expect_equal(report$diff$changes$x$new, "B")
})

test_that("check_drift falls back to structural when key lost", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- stamp(df)
  df <- unkey(df)
  df$x[1] <- 999
  report <- check_drift(df)

  expect_true(report$has_drift)
  expect_null(report$diff)
  expect_true(report$key_lost)
  expect_true(report$content_changed)
})

test_that(".silent suppresses stamp output", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)

  # .silent = TRUE should produce no message
  expect_no_message(stamp(df, .silent = TRUE))

  # Default should produce a message
  expect_message(stamp(df), "Snapshot committed")
})

test_that("list_snapshots includes size_mb column", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  stamp(df)

  result <- list_snapshots()
  expect_true("size_mb" %in% names(result))
  expect_true(result$size_mb[1] > 0)
})
