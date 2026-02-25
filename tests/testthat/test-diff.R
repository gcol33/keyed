# test-diff.R

# diff.keyed_df() tests -------------------------------------------------------

test_that("diff() errors when x is not keyed", {
  # Plain data frames dispatch to base::diff, not diff.keyed_df

  # Calling the method directly to test validation
  df1 <- data.frame(id = 1:3, x = 1:3)
  df2 <- data.frame(id = 1:3, x = 1:3)
  expect_error(diff.keyed_df(df1, df2), "must be keyed")
})

test_that("diff() errors when y is not a data frame", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  expect_error(diff(df, "not a df"), "must be a data frame")
})

test_that("diff() errors when key columns missing from y", {
  df1 <- key(data.frame(id = 1:3, x = 1:3), id)
  df2 <- data.frame(other = 1:3, x = 1:3)
  expect_error(diff(df1, df2), "not found in y")
})

test_that("diff() detects no differences on identical data", {
  df1 <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df2 <- data.frame(id = 1:3, x = c("a", "b", "c"))
  result <- diff(df1, df2)

  expect_s3_class(result, "keyed_diff")
  expect_equal(result$n_removed, 0)
  expect_equal(result$n_added, 0)
  expect_equal(result$n_modified, 0)
  expect_equal(result$n_unchanged, 3)
  expect_equal(length(result$changes), 0)
})

test_that("diff() detects removed rows", {
  df1 <- key(data.frame(id = 1:3, x = 1:3), id)
  df2 <- data.frame(id = 2:3, x = 2:3)
  result <- diff(df1, df2)

  expect_equal(result$n_removed, 1)
  expect_equal(result$removed$id, 1)
  expect_equal(result$n_added, 0)
})

test_that("diff() detects added rows", {
  df1 <- key(data.frame(id = 1:3, x = 1:3), id)
  df2 <- data.frame(id = 1:4, x = 1:4)
  result <- diff(df1, df2)

  expect_equal(result$n_added, 1)
  expect_equal(result$added$id, 4)
  expect_equal(result$n_removed, 0)
})

test_that("diff() detects modified cells", {
  df1 <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df2 <- data.frame(id = 1:3, x = c("a", "B", "c"))
  result <- diff(df1, df2)

  expect_equal(result$n_modified, 1)
  expect_equal(result$n_unchanged, 2)
  expect_true("x" %in% names(result$changes))
  expect_equal(result$changes$x$old, "b")
  expect_equal(result$changes$x$new, "B")
})

test_that("diff() handles NA values correctly", {
  df1 <- key(data.frame(id = 1:3, x = c(1, NA, 3)), id)
  df2 <- data.frame(id = 1:3, x = c(1, NA, 3))
  result <- diff(df1, df2)

  # Both NA = same, no change expected
  expect_equal(result$n_modified, 0)
  expect_equal(result$n_unchanged, 3)
})

test_that("diff() detects NA-to-value and value-to-NA changes", {
  df1 <- key(data.frame(id = 1:3, x = c(1, NA, 3)), id)
  df2 <- data.frame(id = 1:3, x = c(1, 2, NA))
  result <- diff(df1, df2)

  expect_equal(result$n_modified, 2)
  expect_true("x" %in% names(result$changes))
  expect_equal(nrow(result$changes$x), 2)
})

test_that("diff() works with composite keys", {
  df1 <- key(data.frame(a = c(1, 1, 2), b = c(1, 2, 1), x = c("x", "y", "z")), a, b)
  df2 <- data.frame(a = c(1, 1, 2), b = c(1, 2, 1), x = c("x", "Y", "z"))
  result <- diff(df1, df2)

  expect_equal(result$n_modified, 1)
  expect_equal(result$n_unchanged, 2)
  expect_equal(result$changes$x$old, "y")
  expect_equal(result$changes$x$new, "Y")
})

test_that("diff() reports columns only in x or y", {
  df1 <- key(data.frame(id = 1:3, x = 1:3, extra_x = 1:3), id)
  df2 <- data.frame(id = 1:3, x = 1:3, extra_y = 4:6)
  result <- diff(df1, df2)

  expect_equal(result$cols_only_x, "extra_x")
  expect_equal(result$cols_only_y, "extra_y")
})

test_that("diff() handles simultaneous add, remove, modify", {
  df1 <- key(data.frame(id = 1:4, x = c("a", "b", "c", "d")), id)
  df2 <- data.frame(id = c(2, 3, 5), x = c("B", "c", "e"))
  result <- diff(df1, df2)

  expect_equal(result$n_removed, 2)  # ids 1 and 4
  expect_equal(result$n_added, 1)    # id 5
  expect_equal(result$n_modified, 1) # id 2: b -> B
  expect_equal(result$n_unchanged, 1) # id 3: unchanged
})

test_that("diff() handles multiple value columns", {
  df1 <- key(data.frame(id = 1:3, x = 1:3, y = c("a", "b", "c")), id)
  df2 <- data.frame(id = 1:3, x = c(1, 99, 3), y = c("a", "b", "C"))
  result <- diff(df1, df2)

  expect_equal(result$n_modified, 2) # rows 2 and 3
  expect_true("x" %in% names(result$changes))
  expect_true("y" %in% names(result$changes))
  expect_equal(nrow(result$changes$x), 1)
  expect_equal(nrow(result$changes$y), 1)
})

test_that("diff() handles empty common rows (all removed, all added)", {
  df1 <- key(data.frame(id = 1:3, x = 1:3), id)
  df2 <- data.frame(id = 4:6, x = 4:6)
  result <- diff(df1, df2)

  expect_equal(result$n_removed, 3)
  expect_equal(result$n_added, 3)
  expect_equal(result$n_modified, 0)
  expect_equal(result$n_unchanged, 0)
})

test_that("diff() works with single value column", {
  df1 <- key(data.frame(id = 1:2, val = c(10, 20)), id)
  df2 <- data.frame(id = 1:2, val = c(10, 25))
  result <- diff(df1, df2)

  expect_equal(result$n_modified, 1)
  expect_equal(result$changes$val$old, 20)
  expect_equal(result$changes$val$new, 25)
})

# print.keyed_diff() tests ----------------------------------------------------

test_that("print.keyed_diff() shows no differences", {
  df1 <- key(data.frame(id = 1:3, x = 1:3), id)
  df2 <- data.frame(id = 1:3, x = 1:3)
  result <- diff(df1, df2)

  expect_invisible(print(result))
})

test_that("print.keyed_diff() shows full summary", {
  df1 <- key(data.frame(id = 1:4, x = c("a", "b", "c", "d")), id)
  df2 <- data.frame(id = c(2, 3, 5), x = c("B", "c", "e"))
  result <- diff(df1, df2)

  expect_invisible(print(result))
})
