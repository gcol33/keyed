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
