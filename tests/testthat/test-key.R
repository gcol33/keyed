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

test_that("key<- errors with non-character value", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_error(key(df) <- 1, "character vector")
})

test_that("key() errors when no columns specified", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_error(key(df), "At least one key column")
})

test_that("key() skips validation when .validate = FALSE", {
  df <- data.frame(id = c(1, 1, 2), x = c("a", "b", "c"))
  expect_silent(result <- key(df, id, .validate = FALSE))
  expect_true(has_key(result))
})

test_that("key_is_valid() returns FALSE for non-keyed data", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_false(key_is_valid(df))
})

test_that("key_is_valid() detects non-unique keys", {
  df <- key(data.frame(id = c(1, 1, 2), x = 1:3), id, .validate = FALSE)
  expect_warning(result <- key_is_valid(df), "no longer unique")
  expect_false(result)
})

test_that("has_key() returns FALSE for plain data frames", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_false(has_key(df))
})

test_that("get_key_cols() returns NULL for plain data frames", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_null(get_key_cols(df))
})

test_that("print.keyed_df() works", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  expect_output(print(df), "keyed tibble")
})

test_that("tbl_sum.keyed_df() shows key info", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  summary <- pillar::tbl_sum(df)
  expect_true(any(grepl("Key", names(summary))))
})

test_that("tbl_sum.keyed_df() shows id when present", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df <- add_id(df)
  summary <- pillar::tbl_sum(df)
  expect_true(any(grepl("\\.id", summary)))
})

test_that("summary.keyed_df() returns diagnostic info", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  result <- summary(df)
  expect_equal(result$nrow, 3)
  expect_equal(result$key_cols, "id")
})

test_that("summary.keyed_df() handles NA in keys", {
  df <- key(data.frame(id = c(1, NA, 3), x = c("a", "b", "c")), id, .validate = FALSE)
  result <- summary(df)
  expect_equal(result$nrow, 3)
})

test_that("summary.keyed_df() handles duplicate keys", {
  df <- key(data.frame(id = c(1, 1, 2), x = c("a", "b", "c")), id, .validate = FALSE)
  result <- summary(df)
  expect_equal(result$nrow, 3)
})

test_that("summary.keyed_df() handles missing column", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df$id <- NULL
  class(df) <- c("keyed_df", class(df))
  attr(df, "keyed_cols") <- "id"
  result <- summary(df)
  expect_equal(result$key_cols, "id")
})

test_that("summary.keyed_df() shows row ID info", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df <- add_id(df)
  result <- summary(df)
  expect_true(result$has_id)
})

test_that("summary.keyed_df() handles ID issues", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df$.id <- c("a", "a", NA)
  result <- summary(df)
  expect_true(result$has_id)
})

test_that("summary.keyed_df() handles snapshot", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df <- commit_keyed(df)
  result <- summary(df)
  expect_equal(result$nrow, 3)
})
