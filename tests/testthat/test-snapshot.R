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
