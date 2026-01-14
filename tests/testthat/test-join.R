test_that("diagnose_join detects cardinality", {
  x <- data.frame(id = c(1, 1, 2), a = 1:3)
  y <- data.frame(id = c(1, 2, 2), b = 1:3)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_equal(diag$cardinality, "many-to-many")
  expect_false(diag$x_unique)
  expect_false(diag$y_unique)
})

test_that("diagnose_join identifies one-to-one", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = 1:3, b = 4:6)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_equal(diag$cardinality, "one-to-one")
  expect_true(diag$x_unique)
  expect_true(diag$y_unique)
})

test_that("diagnose_join identifies one-to-many", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = c(1, 1, 2), b = 1:3)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_equal(diag$cardinality, "one-to-many")
  expect_true(diag$x_unique)
  expect_false(diag$y_unique)
})

test_that("diagnose_join estimates explosion size", {
  x <- data.frame(id = c(1, 1), a = 1:2)
  y <- data.frame(id = c(1, 1), b = 1:2)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_equal(diag$max_result_rows, 4)  # 2 x 2
})

test_that("diagnose_join identifies many-to-one", {
  x <- data.frame(id = c(1, 1, 2), a = 1:3)
  y <- data.frame(id = 1:3, b = 4:6)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_equal(diag$cardinality, "many-to-one")
  expect_false(diag$x_unique)
  expect_true(diag$y_unique)
})

test_that("diagnose_join uses natural join when by is NULL", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = 1:3, b = 4:6)

  diag <- diagnose_join(x, y, by = NULL, use_joinspy = FALSE)
  expect_equal(diag$cardinality, "one-to-one")
})

test_that("diagnose_join handles named by specification", {
  x <- data.frame(x_id = 1:3, a = 1:3)
  y <- data.frame(y_id = 1:3, b = 4:6)

  diag <- diagnose_join(x, y, by = c("x_id" = "y_id"), use_joinspy = FALSE)
  expect_equal(diag$cardinality, "one-to-one")
})

test_that("diagnose_join handles empty data frames", {
  x <- data.frame(id = integer(), a = integer())
  y <- data.frame(id = 1:3, b = 4:6)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_true(diag$x_unique)
  expect_equal(diag$max_result_rows, 0)
})

test_that("diagnose_join handles no matching keys", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = 4:6, b = 4:6)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_equal(diag$max_result_rows, 0)
})

test_that("print.keyed_join_diagnosis works", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = 1:3, b = 4:6)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_invisible(print(diag))
  expect_equal(diag$cardinality, "one-to-one")
})

test_that("print.keyed_join_diagnosis shows duplicates", {
  x <- data.frame(id = c(1, 1, 2), a = 1:3)
  y <- data.frame(id = 1:3, b = 4:6)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_invisible(print(diag))
  expect_equal(diag$x_duplicates, 1)
})

test_that("print.keyed_join_diagnosis warns about many-to-many", {
  x <- data.frame(id = c(1, 1), a = 1:2)
  y <- data.frame(id = c(1, 1), b = 1:2)

  diag <- diagnose_join(x, y, by = "id", use_joinspy = FALSE)
  expect_invisible(print(diag))
  expect_equal(diag$cardinality, "many-to-many")
})

test_that("count_duplicates returns 0 for empty columns", {
  df <- data.frame(id = 1:3, x = 1:3)
  result <- keyed:::count_duplicates(df, character())
  expect_equal(result, 0)
})

test_that("count_duplicates returns 0 for empty data frame", {
  df <- data.frame(id = integer(), x = integer())
  result <- keyed:::count_duplicates(df, "id")
  expect_equal(result, 0)
})

test_that("is_unique_on returns TRUE for empty columns", {
  df <- data.frame(id = 1:3, x = 1:3)
  result <- keyed:::is_unique_on(df, character())
  expect_true(result)
})

test_that("is_unique_on returns TRUE for empty data frame", {
  df <- data.frame(id = integer(), x = integer())
  result <- keyed:::is_unique_on(df, "id")
  expect_true(result)
})
