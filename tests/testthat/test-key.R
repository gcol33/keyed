test_that("key() creates keyed_df", {
  df <- data.frame(id = 1:3, x = c("a", "b", "c"))
  result <- key(df, id)

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), "id")
  expect_true(has_key(result))
})

test_that("key() works with composite keys", {
  df <- data.frame(
    country = c("US", "US", "UK"),
    year = c(2020, 2021, 2020),
    val = 1:3
  )
  result <- key(df, country, year)

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), c("country", "year"))
})

test_that("key() validates uniqueness by default", {
  df <- data.frame(id = c(1, 1, 2), x = c("a", "b", "c"))
  expect_warning(key(df, id), "not unique")
})
test_that("key() errors on non-unique keys in strict mode", {
  df <- data.frame(id = c(1, 1, 2), x = c("a", "b", "c"))
  expect_error(key(df, id, .strict = TRUE), "not unique")
})

test_that("key() errors when column doesn't exist", {
  df <- data.frame(id = 1:3, x = c("a", "b", "c"))
  expect_error(key(df, nonexistent), "not found")
})

test_that("unkey() removes key metadata", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- unkey(df)

  expect_false(has_key(result))
  expect_null(get_key_cols(result))
  expect_false(inherits(result, "keyed_df"))
})

test_that("key_is_valid() detects invalid keys", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  expect_true(key_is_valid(df))

  # Remove key column
  df2 <- df
  df2$id <- NULL
  class(df2) <- class(df)
  attr(df2, "keyed_cols") <- "id"
  expect_warning(result <- key_is_valid(df2))
  expect_false(result)
})

test_that("key<- assignment works", {
  df <- data.frame(id = 1:3, x = 1:3)
  key(df) <- "id"

  expect_true(has_key(df))
  expect_equal(get_key_cols(df), "id")
})
