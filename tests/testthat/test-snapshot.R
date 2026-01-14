test_that("commit_keyed creates snapshot", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)

  # Clear any existing snapshots
  keyed:::clear_all_snapshots(confirm = FALSE)

  result <- commit_keyed(df)

  expect_true(!is.null(attr(result, "keyed_snapshot_ref")))
  expect_equal(nrow(list_snapshots()), 1)
})

test_that("check_drift detects no change", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- commit_keyed(df)
  report <- check_drift(df)

  expect_false(report$has_drift)
})

test_that("check_drift detects content changes", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- commit_keyed(df)
  df$x[1] <- 999
  report <- check_drift(df)

  expect_true(report$has_drift)
  expect_true(report$content_changed)
})

test_that("check_drift detects row count changes", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- commit_keyed(df)
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

  df <- commit_keyed(df)
  df$y <- 4:6
  report <- check_drift(df)

  expect_true(report$has_drift)
  expect_equal(report$cols_added, "y")
})

test_that("clear_snapshot removes reference", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- commit_keyed(df)
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
  commit_keyed(df, name = "test_snap")

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
  commit_keyed(df)

  expect_message(clear_all_snapshots(confirm = TRUE), "remove")
})

test_that("clear_snapshot with purge removes from cache", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- commit_keyed(df)
  ref <- attr(df, "keyed_snapshot_ref")

  df <- clear_snapshot(df, purge = TRUE)
  expect_null(keyed:::get_snapshot(ref))
})

test_that("check_drift warns when snapshot not in cache", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- commit_keyed(df)

  # Manually clear cache to simulate eviction
  keyed:::clear_all_snapshots(confirm = FALSE)

  expect_warning(report <- check_drift(df), "Snapshot not found")
  expect_null(report)
})

test_that("print.keyed_drift_report shows no drift", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- commit_keyed(df)
  report <- check_drift(df)

  expect_false(report$has_drift)
  expect_invisible(print(report))
})

test_that("print.keyed_drift_report shows drift details", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- commit_keyed(df)
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
  df <- commit_keyed(df)
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
  df <- commit_keyed(df)
  df$y <- NULL
  report <- check_drift(df)

  expect_equal(report$cols_removed, "y")
  expect_invisible(print(report))
})

test_that("print.keyed_drift_report shows key loss", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- commit_keyed(df)
  df <- unkey(df)
  report <- check_drift(df)

  expect_true(report$key_lost)
  expect_invisible(print(report))
})

test_that("print.keyed_drift_report shows cell value changes", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- commit_keyed(df)
  df$x[1] <- 999
  report <- check_drift(df)

  # Cell values changed without row/column changes
  expect_true(report$content_changed)
  expect_false(report$nrow_changed)
  expect_equal(length(report$cols_added), 0)
})

test_that("commit_keyed with name parameter", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- commit_keyed(df, name = "my_snapshot")

  snaps <- list_snapshots()
  expect_equal(snaps$name, "my_snapshot")
})

test_that("check_drift detects key value changes", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df <- commit_keyed(df)
  df$id[1] <- 10
  report <- check_drift(df)

  expect_true(report$key_values_changed)
})
