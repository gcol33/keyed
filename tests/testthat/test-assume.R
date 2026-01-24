test_that("lock_unique passes for unique values", {
  df <- data.frame(id = 1:3, x = c("a", "b", "c"))
  expect_silent(lock_unique(df, id))
})

test_that("lock_unique warns for duplicates", {
  df <- data.frame(id = c(1, 1, 2), x = c("a", "b", "c"))
  expect_warning(lock_unique(df, id), "Uniqueness assumption violated")
})

test_that("lock_unique errors in strict mode", {
  df <- data.frame(id = c(1, 1, 2), x = c("a", "b", "c"))
  expect_error(lock_unique(df, id, .strict = TRUE), class = "keyed_assumption_error")
})

test_that("lock_unique works with composite keys", {
  df <- data.frame(a = c(1, 1, 2), b = c(1, 2, 1), x = 1:3)
  expect_silent(lock_unique(df, a, b))
})

test_that("lock_no_na passes for complete data", {
  df <- data.frame(id = 1:3, x = c("a", "b", "c"))
  expect_silent(lock_no_na(df, id, x))
})

test_that("lock_no_na warns for NA values", {
  df <- data.frame(id = 1:3, x = c("a", NA, "c"))
  expect_warning(lock_no_na(df, x), "No-NA assumption violated")
})

test_that("lock_complete checks all columns", {
  df <- data.frame(id = 1:3, x = c("a", NA, "c"))
  expect_warning(lock_complete(df), "No-NA assumption violated")
})

test_that("lock_coverage passes when threshold met", {
  df <- data.frame(id = 1:10, x = c(1:8, NA, NA))
  expect_silent(lock_coverage(df, 0.8, x))
})

test_that("lock_coverage warns below threshold", {
  df <- data.frame(id = 1:10, x = c(1:8, NA, NA))
  expect_warning(lock_coverage(df, 0.9, x), "Coverage assumption violated")
})

test_that("lock_nrow passes for correct count", {
  df <- data.frame(id = 1:100)
  expect_silent(lock_nrow(df, min = 50, max = 200))
  expect_silent(lock_nrow(df, expected = 100))
})

test_that("lock_nrow warns for incorrect count", {
  df <- data.frame(id = 1:100)
  expect_warning(lock_nrow(df, min = 200), "Row count assumption violated")
  expect_warning(lock_nrow(df, expected = 50), "Row count assumption violated")
})

test_that("lock functions return data invisibly for piping", {
  df <- data.frame(id = 1:3, x = 1:3)
  result <- lock_unique(df, id)
  expect_identical(result, df)
})

test_that("lock_unique errors when no columns specified", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_error(lock_unique(df), "At least one column")
})

test_that("lock_unique errors when column not found", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_error(lock_unique(df, nonexistent), "not found")
})

test_that("lock_no_na checks all columns when none specified", {
  df <- data.frame(id = 1:3, x = c("a", NA, "c"))
  expect_warning(lock_no_na(df), "No-NA assumption violated")
})

test_that("lock_no_na errors when column not found", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_error(lock_no_na(df, nonexistent), "not found")
})

test_that("lock_no_na errors in strict mode", {
  df <- data.frame(id = 1:3, x = c("a", NA, "c"))
  expect_error(lock_no_na(df, x, .strict = TRUE), class = "keyed_assumption_error")
})

test_that("lock_coverage errors with invalid threshold", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_error(lock_coverage(df, 1.5, x), "between 0 and 1")
  expect_error(lock_coverage(df, -0.1, x), "between 0 and 1")
  expect_error(lock_coverage(df, c(0.5, 0.6), x), "single number")
})

test_that("lock_coverage errors when column not found", {
  df <- data.frame(id = 1:3, x = 1:3)
  expect_error(lock_coverage(df, 0.8, nonexistent), "not found")
})

test_that("lock_coverage handles empty data frame", {
  df <- data.frame(id = integer(), x = integer())
  expect_silent(lock_coverage(df, 0.9))
})

test_that("lock_coverage checks all columns when none specified", {
  df <- data.frame(id = 1:10, x = c(1:8, NA, NA))
  expect_warning(lock_coverage(df, 0.9), "Coverage assumption violated")
})

test_that("lock_coverage errors in strict mode", {
  df <- data.frame(id = 1:10, x = c(1:8, NA, NA))
  expect_error(lock_coverage(df, 0.9, x, .strict = TRUE), class = "keyed_assumption_error")
})

test_that("lock_nrow with max constraint", {
  df <- data.frame(id = 1:100)
  expect_silent(lock_nrow(df, min = 0, max = 200))
  expect_warning(lock_nrow(df, min = 0, max = 50), "Row count assumption violated")
})

test_that("lock_nrow errors in strict mode", {
  df <- data.frame(id = 1:100)
  expect_error(lock_nrow(df, expected = 50, .strict = TRUE), class = "keyed_assumption_error")
  expect_error(lock_nrow(df, min = 200, .strict = TRUE), class = "keyed_assumption_error")
})
