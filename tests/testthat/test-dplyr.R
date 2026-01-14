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
  df <- key(data.frame(id = c(1, 1, 2), x = 1:3), id)
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
