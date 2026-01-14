test_that("filter preserves key", {
  df <- key(data.frame(id = 1:5, x = 1:5), id)
  result <- dplyr::filter(df, id > 2)

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), "id")
  expect_equal(nrow(result), 3)
})

test_that("select preserves key when key columns kept", {
  df <- key(data.frame(id = 1:3, x = 1:3, y = 4:6), id)
  result <- dplyr::select(df, id, x)

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), "id")
})

test_that("select warns when key column dropped", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  expect_warning(result <- dplyr::select(df, x), "Key column")
  expect_false(has_key(result))
})

test_that("mutate preserves key", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- dplyr::mutate(df, y = x * 2)

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), "id")
})

test_that("mutate warns when key becomes non-unique", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  expect_warning(result <- dplyr::mutate(df, id = 1), "no longer unique")
  expect_false(has_key(result))
})

test_that("arrange preserves key", {
  df <- key(data.frame(id = c(3, 1, 2), x = c("c", "a", "b")), id)
  result <- dplyr::arrange(df, id)

  expect_s3_class(result, "keyed_df")
  expect_equal(result$id, c(1, 2, 3))
})

test_that("rename updates key column name", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- dplyr::rename(df, new_id = id)

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), "new_id")
})

test_that("summarise degrades to tibble", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- dplyr::summarise(df, total = sum(x))

  expect_false(has_key(result))
})

test_that("summarise preserves key when grouped by key", {
  df <- suppressWarnings(key(data.frame(id = c(1, 1, 2), x = 1:3), id))
  df <- dplyr::group_by(df, id)
  result <- dplyr::summarise(df, total = sum(x))

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), "id")
})

test_that("slice preserves key", {
  df <- key(data.frame(id = 1:5, x = 1:5), id)
  result <- dplyr::slice(df, 1:3)

  expect_s3_class(result, "keyed_df")
  expect_equal(nrow(result), 3)
})

test_that("distinct preserves key when still unique", {
  df <- key(data.frame(id = 1:3, x = c("a", "a", "b")), id)
  result <- dplyr::distinct(df)

  expect_s3_class(result, "keyed_df")
})

test_that("group_by preserves key", {
  df <- key(data.frame(id = 1:3, grp = c("a", "a", "b"), x = 1:3), id)
  result <- dplyr::group_by(df, grp)

  expect_true(has_key(result))
  expect_equal(get_key_cols(result), "id")
})

test_that("ungroup preserves key", {
  df <- key(data.frame(id = 1:3, grp = c("a", "a", "b"), x = 1:3), id)
  df <- dplyr::group_by(df, grp)
  result <- dplyr::ungroup(df)

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), "id")
})

test_that("distinct on non-key column preserves key when unique", {
  df <- key(data.frame(id = c(1, 2, 3), x = c("a", "a", "b")), id)
  result <- dplyr::distinct(df, x, .keep_all = TRUE)

  # After distinct on x, only 2 rows remain with ids 1 and 3
  # Key should still be valid and unique
  expect_equal(nrow(result), 2)
})

test_that("bind_keyed combines keyed data frames", {
  df1 <- key(data.frame(id = 1:2, x = 1:2), id)
  df2 <- key(data.frame(id = 3:4, x = 3:4), id)
  result <- bind_keyed(df1, df2)

  expect_s3_class(result, "keyed_df")
  expect_equal(nrow(result), 4)
  expect_equal(get_key_cols(result), "id")
})

test_that("bind_keyed warns on non-unique keys", {
  df1 <- key(data.frame(id = 1:2, x = 1:2), id)
  df2 <- key(data.frame(id = 1:2, x = 3:4), id)

  expect_warning(result <- bind_keyed(df1, df2), "not unique")
  expect_false(has_key(result))
})

test_that("bind_keyed works with unkeyed data", {
  df1 <- data.frame(id = 1:2, x = 1:2)
  df2 <- data.frame(id = 3:4, x = 3:4)
  result <- bind_keyed(df1, df2)

  expect_false(has_key(result))
  expect_equal(nrow(result), 4)
})

test_that("bind_keyed with .id parameter", {
  df1 <- key(data.frame(id = 1:2, x = 1:2), id)
  df2 <- key(data.frame(id = 3:4, x = 3:4), id)
  result <- bind_keyed(df1, df2, .id = "source")

  expect_true("source" %in% names(result))
})

test_that("mutate preserves key when key modified but still unique", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- dplyr::mutate(df, id = id + 10)

  expect_s3_class(result, "keyed_df")
  expect_equal(result$id, c(11, 12, 13))
})

test_that("summarize alias works", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- dplyr::summarize(df, total = sum(x))

  expect_false(has_key(result))
})

test_that("dplyr_reconstruct preserves key on simple operations", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- df[1:2, ]

  expect_s3_class(result, "keyed_df")
})

test_that("transmute drops key when key column not included", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  # transmute keeps only the specified columns
  result <- dplyr::transmute(df, y = x * 2)

  # Key column 'id' was not included, so key should be gone
  expect_false("id" %in% names(result))
})

test_that("dplyr_reconstruct handles null key gracefully", {
  df <- data.frame(id = 1:3, x = 1:3)
  class(df) <- c("keyed_df", class(df))
  attr(df, "keyed_cols") <- NULL

  result <- dplyr::filter(df, id > 1)
  expect_s3_class(result, "tbl_df")
})

test_that("filter degrades when key column removed via subsetting", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  df$id <- NULL
  class(df) <- c("keyed_df", class(df))
  attr(df, "keyed_cols") <- "id"

  result <- dplyr::filter(df, x > 1)
  expect_s3_class(result, "tbl_df")
})

test_that("rename preserves key for non-key columns", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- dplyr::rename(df, y = x)

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), "id")
  expect_true("y" %in% names(result))
})

test_that("select with everything() preserves key", {
  df <- key(data.frame(id = 1:3, x = 1:3), id)
  result <- dplyr::select(df, dplyr::everything())

  expect_s3_class(result, "keyed_df")
  expect_equal(get_key_cols(result), "id")
})
