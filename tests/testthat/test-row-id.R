test_that("add_id adds column", {
  df <- data.frame(x = 1:3)
  result <- add_id(df)

  expect_true(has_id(result))
  expect_equal(names(result)[1], ".id")
  expect_equal(length(unique(result$.id)), 3)
})

test_that("add_id uses custom column name", {
  df <- data.frame(x = 1:3)
  result <- add_id(df, .id = "my_id")

  expect_true(has_id(result, .id = "my_id"))
  expect_true("my_id" %in% names(result))
})

test_that("add_id errors on existing column", {
  df <- data.frame(.id = 1:3, x = 1:3)
  expect_error(add_id(df), "already exists")
})

test_that("add_id can overwrite", {
  df <- data.frame(.id = 1:3, x = 1:3)
  result <- add_id(df, .overwrite = TRUE)

  expect_true(has_id(result))
  expect_false(identical(df$.id, result$.id))
})

test_that("get_id returns IDs", {
  df <- add_id(data.frame(x = 1:3))
  ids <- get_id(df)

  expect_length(ids, 3)
  expect_type(ids, "character")
})

test_that("remove_id removes column", {
  df <- add_id(data.frame(x = 1:3))
  result <- remove_id(df)

  expect_false(has_id(result))
  expect_false(".id" %in% names(result))
})

test_that("compare_ids detects changes", {
  df1 <- add_id(data.frame(x = 1:5))
  df2 <- df1[1:3, ]

  comparison <- compare_ids(df1, df2)

  expect_length(comparison$lost, 2)
  expect_length(comparison$gained, 0)
  expect_length(comparison$preserved, 3)
})

test_that("extend_id fills NA IDs", {
  old <- add_id(data.frame(x = 1:3))
  new <- data.frame(.id = NA_character_, x = 4:5)
  combined <- dplyr::bind_rows(old, new)

  result <- extend_id(combined)

  expect_false(any(is.na(result$.id)))
  expect_equal(result$.id[1:3], old$.id)  # preserved
  expect_length(unique(result$.id), 5)     # all unique
})

test_that("extend_id does nothing when no NAs", {
  df <- add_id(data.frame(x = 1:3))
  result <- extend_id(df)
  expect_equal(df, result)
})

test_that("extend_id errors without ID column", {
  df <- data.frame(x = 1:3)
  expect_error(extend_id(df), "not found")
})

test_that("make_id creates composite ID", {
  df <- data.frame(country = c("US", "UK"), year = c(2020, 2021))
  result <- make_id(df, country, year)

  expect_true(".id" %in% names(result))
  expect_equal(result$.id, c("US|2020", "UK|2021"))
})

test_that("make_id uses custom separator", {
  df <- data.frame(a = 1:2, b = 3:4)
  result <- make_id(df, a, b, .sep = "_")

  expect_equal(result$.id, c("1_3", "2_4"))
})

test_that("make_id errors on existing column", {
  df <- data.frame(.id = 1:3, x = 1:3)
  expect_error(make_id(df, x), "already exists")
})

# check_id tests ---------------------------------------------------------------

test_that("check_id validates good IDs", {
  df <- add_id(data.frame(x = 1:3))
  result <- check_id(df)

  expect_true(result$valid)
  expect_equal(result$n_na, 0)
  expect_equal(result$n_duplicates, 0)
  expect_true(result$format_ok)
})

test_that("check_id warns on NAs", {
  df <- data.frame(.id = c("abc123def456", NA, "xyz789ghi012"), x = 1:3)
  expect_warning(result <- check_id(df), "NA value")

  expect_false(result$valid)
  expect_equal(result$n_na, 1)
})

test_that("check_id warns on duplicates", {
  df <- data.frame(.id = c("abc123def456", "abc123def456", "xyz789ghi012"), x = 1:3)
  expect_warning(result <- check_id(df), "duplicate")

  expect_false(result$valid)
  expect_equal(result$n_duplicates, 1)
})

test_that("check_id warns on short IDs", {
  df <- data.frame(.id = c("abc", "def", "ghi"), x = 1:3)
  expect_warning(result <- check_id(df), "short")

  expect_false(result$format_ok)
})

test_that("check_id warns on numeric IDs", {
  df <- data.frame(.id = c("1", "2", "3"), x = 1:3)
  expect_warning(result <- check_id(df), "numeric")

  expect_false(result$format_ok)
})

test_that("check_id errors without ID column", {
  df <- data.frame(x = 1:3)
  expect_error(check_id(df), "not found")
})

# check_id_disjoint tests ------------------------------------------------------

test_that("check_id_disjoint passes for disjoint IDs", {
  df1 <- add_id(data.frame(x = 1:3))
  df2 <- add_id(data.frame(x = 4:6))
  result <- check_id_disjoint(df1, df2)

  expect_true(result$disjoint)
  expect_length(result$overlaps, 0)
})

test_that("check_id_disjoint warns on overlaps", {
  df1 <- data.frame(.id = c("a", "b", "c"), x = 1:3)
  df2 <- data.frame(.id = c("b", "c", "d"), x = 4:6)
  expect_warning(result <- check_id_disjoint(df1, df2), "overlapping")

  expect_false(result$disjoint)
  expect_equal(sort(result$overlaps), c("b", "c"))
})

test_that("check_id_disjoint works with multiple datasets", {
  df1 <- data.frame(.id = c("a", "b"), x = 1:2)
  df2 <- data.frame(.id = c("c", "d"), x = 3:4)
  df3 <- data.frame(.id = c("e", "f"), x = 5:6)
  result <- check_id_disjoint(df1, df2, df3)

  expect_true(result$disjoint)
})

test_that("check_id_disjoint errors with single dataset", {
  df <- add_id(data.frame(x = 1:3))
  expect_error(check_id_disjoint(df), "At least two")
})

test_that("check_id_disjoint errors without ID column", {
  df1 <- add_id(data.frame(x = 1:3))
  df2 <- data.frame(x = 4:6)  # No ID
  expect_error(check_id_disjoint(df1, df2), "does not have")
})
