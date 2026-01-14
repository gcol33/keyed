test_that("assume_unique passes for unique values", {
  df <- data.frame(id = 1:3, x = c("a", "b", "c"))
  expect_silent(assume_unique(df, id))
})

test_that("assume_unique warns for duplicates", {
  df <- data.frame(id = c(1, 1, 2), x = c("a", "b", "c"))
  expect_warning(assume_unique(df, id), "Uniqueness assumption violated")
})

test_that("assume_unique errors in strict mode", {
  df <- data.frame(id = c(1, 1, 2), x = c("a", "b", "c"))
  expect_error(assume_unique(df, id, .strict = TRUE), class = "keyed_assumption_error")
})

test_that("assume_unique works with composite keys", {
  df <- data.frame(a = c(1, 1, 2), b = c(1, 2, 1), x = 1:3)
  expect_silent(assume_unique(df, a, b))
})

test_that("assume_no_na passes for complete data", {
  df <- data.frame(id = 1:3, x = c("a", "b", "c"))
  expect_silent(assume_no_na(df, id, x))
})

test_that("assume_no_na warns for NA values", {
  df <- data.frame(id = 1:3, x = c("a", NA, "c"))
  expect_warning(assume_no_na(df, x), "No-NA assumption violated")
})

test_that("assume_complete checks all columns", {
  df <- data.frame(id = 1:3, x = c("a", NA, "c"))
  expect_warning(assume_complete(df), "No-NA assumption violated")
})

test_that("assume_coverage passes when threshold met", {
  df <- data.frame(id = 1:10, x = c(1:8, NA, NA))
  expect_silent(assume_coverage(df, 0.8, x))
})

test_that("assume_coverage warns below threshold", {
  df <- data.frame(id = 1:10, x = c(1:8, NA, NA))
  expect_warning(assume_coverage(df, 0.9, x), "Coverage assumption violated")
})

test_that("assume_nrow passes for correct count", {
  df <- data.frame(id = 1:100)
  expect_silent(assume_nrow(df, min = 50, max = 200))
  expect_silent(assume_nrow(df, expected = 100))
})

test_that("assume_nrow warns for incorrect count", {
  df <- data.frame(id = 1:100)
  expect_warning(assume_nrow(df, min = 200), "Row count assumption violated")
  expect_warning(assume_nrow(df, expected = 50), "Row count assumption violated")
})

test_that("assume functions return data invisibly for piping", {
  df <- data.frame(id = 1:3, x = 1:3)
  result <- assume_unique(df, id)
  expect_identical(result, df)
})
