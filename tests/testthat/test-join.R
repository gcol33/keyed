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
