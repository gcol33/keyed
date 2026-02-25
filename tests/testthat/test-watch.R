# test-watch.R

# watch() / unwatch() tests ---------------------------------------------------

test_that("watch() errors on non-keyed data", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_error(watch(df), "requires keyed data")
})

test_that("watch() sets watched attribute and auto-stamps baseline", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- watch(df)

  expect_true(keyed:::is_watched(result))
  expect_true(!is.null(attr(result, "keyed_snapshot_ref")))
  expect_equal(nrow(list_snapshots()), 1)
})

test_that("unwatch() removes watched attribute", {
  df <- key(data.frame(id = 1:3, x = 1:3), id) |> watch()
  result <- unwatch(df)

  expect_false(keyed:::is_watched(result))
})

# Auto-stamp on dplyr verbs ---------------------------------------------------

test_that("auto-stamp on filter produces meaningful diff", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:5, x = letters[1:5]), id) |> watch()
  df2 <- df |> dplyr::filter(id > 2)
  report <- check_drift(df2)

  expect_true(report$has_drift)
  expect_s3_class(report$diff, "keyed_diff")
  expect_equal(report$diff$n_removed, 2)
  expect_equal(report$diff$n_unchanged, 3)
})

test_that("auto-stamp on mutate detects cell changes", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id) |> watch()
  df2 <- df |> dplyr::mutate(x = toupper(x))
  report <- check_drift(df2)

  expect_true(report$has_drift)
  expect_s3_class(report$diff, "keyed_diff")
  expect_equal(report$diff$n_modified, 3)
  expect_equal(nrow(report$diff$changes$x), 3)
})

test_that("watched survives pipe chain", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:5, x = letters[1:5]), id) |> watch()
  result <- df |>
    dplyr::filter(id > 1) |>
    dplyr::mutate(x = toupper(x))

  expect_true(keyed:::is_watched(result))
  expect_true(!is.null(attr(result, "keyed_snapshot_ref")))
})

test_that("check_drift after chain shows diff from last step only", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:5, x = letters[1:5]), id) |> watch()
  result <- df |>
    dplyr::filter(id > 2) |>
    dplyr::mutate(x = toupper(x))

  report <- check_drift(result)

  # Should show diff from post-filter to post-mutate (3 cells changed)
  # not from original to final
  expect_s3_class(report$diff, "keyed_diff")
  expect_equal(report$diff$n_modified, 3)
  expect_equal(report$diff$n_removed, 0)
  expect_equal(report$diff$n_added, 0)
})

test_that("summarise on watched data degrades gracefully", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:5, x = 1:5), id) |> watch()

  # summarise without grouping by key → unkeyed result
  expect_no_error({
    result <- df |> dplyr::summarise(total = sum(x))
  })

  # Result should still carry watched and snapshot_ref attrs
  expect_true(keyed:::is_watched(result))
})

test_that("auto-stamp on arrange preserves watched state", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = c("c", "a", "b")), id) |> watch()
  result <- df |> dplyr::arrange(x)

  expect_true(keyed:::is_watched(result))
  expect_true(!is.null(attr(result, "keyed_snapshot_ref")))
})

test_that("auto-stamp on select preserves watched state", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:3, x = 1:3, y = 4:6), id) |> watch()
  result <- df |> dplyr::select(id, x)

  expect_true(keyed:::is_watched(result))
})

test_that("auto-stamp on slice preserves watched state", {
  keyed:::clear_all_snapshots(confirm = FALSE)

  df <- key(data.frame(id = 1:5, x = 1:5), id) |> watch()
  result <- df |> dplyr::slice(1:3)

  expect_true(keyed:::is_watched(result))
  report <- check_drift(result)
  expect_true(report$has_drift)
  expect_equal(report$diff$n_removed, 2)
})
