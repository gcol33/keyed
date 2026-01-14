test_that("add_row_id adds column", {
  df <- data.frame(x = 1:3)
  result <- add_row_id(df)

  expect_true(has_row_id(result))
  expect_equal(names(result)[1], ".row_id")
  expect_equal(length(unique(result$.row_id)), 3)
})

test_that("add_row_id uses custom column name", {
  df <- data.frame(x = 1:3)
  result <- add_row_id(df, .id = "my_id")

  expect_true(has_row_id(result, .id = "my_id"))
  expect_true("my_id" %in% names(result))
})

test_that("add_row_id errors on existing column", {
  df <- data.frame(.row_id = 1:3, x = 1:3)
  expect_error(add_row_id(df), "already exists")
})

test_that("add_row_id can overwrite", {
  df <- data.frame(.row_id = 1:3, x = 1:3)
  result <- add_row_id(df, .overwrite = TRUE)

  expect_true(has_row_id(result))
  expect_false(identical(df$.row_id, result$.row_id))
})

test_that("get_row_id returns IDs", {
  df <- add_row_id(data.frame(x = 1:3))
  ids <- get_row_id(df)

  expect_length(ids, 3)
  expect_type(ids, "character")
})

test_that("remove_row_id removes column", {
  df <- add_row_id(data.frame(x = 1:3))
  result <- remove_row_id(df)

  expect_false(has_row_id(result))
  expect_false(".row_id" %in% names(result))
})

test_that("compare_row_ids detects changes", {
  df1 <- add_row_id(data.frame(x = 1:5))
  df2 <- df1[1:3, ]

  comparison <- compare_row_ids(df1, df2)

  expect_length(comparison$lost, 2)
  expect_length(comparison$gained, 0)
  expect_length(comparison$preserved, 3)
})
