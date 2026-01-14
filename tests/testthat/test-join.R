test_that("left_join_checked works without validation", {
  x <- data.frame(id = 1:3, a = c("x", "y", "z"))
  y <- data.frame(id = 1:2, b = c(10, 20))

  result <- left_join_checked(x, y, by = "id")
  expect_equal(nrow(result), 3)
  expect_true(is.na(result$b[3]))
})

test_that("left_join_checked validates one-to-one", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = 1:3, b = 4:6)

  expect_silent(left_join_checked(x, y, by = "id", expect = "one-to-one"))
})

test_that("left_join_checked warns on one-to-one violation", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = c(1, 1, 2), b = 1:3)

  expect_warning(
    left_join_checked(x, y, by = "id", expect = "one-to-one"),
    "Cardinality assumption violated"
  )
})

test_that("left_join_checked validates coverage", {
  x <- data.frame(id = 1:10, a = 1:10)
  y <- data.frame(id = 1:8, b = 1:8)

  expect_silent(left_join_checked(x, y, by = "id", coverage = 0.8))
  expect_warning(
    left_join_checked(x, y, by = "id", coverage = 0.9),
    "Coverage assumption violated"
  )
})

test_that("left_join_checked errors in strict mode", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = c(1, 1, 2), b = 1:3)

  expect_error(
    left_join_checked(x, y, by = "id", expect = "one-to-one", .strict = TRUE),
    class = "keyed_join_error"
  )
})

test_that("inner_join_checked works", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = 2:4, b = 1:3)

  result <- inner_join_checked(x, y, by = "id")
  expect_equal(nrow(result), 2)
})

test_that("diagnose_join detects cardinality", {
  x <- data.frame(id = c(1, 1, 2), a = 1:3)
  y <- data.frame(id = c(1, 2, 2), b = 1:3)

  diag <- diagnose_join(x, y, by = "id")
  expect_equal(diag$cardinality, "many-to-many")
  expect_false(diag$x_unique)
  expect_false(diag$y_unique)
})

test_that("diagnose_join identifies one-to-one", {
  x <- data.frame(id = 1:3, a = 1:3)
  y <- data.frame(id = 1:3, b = 4:6)

  diag <- diagnose_join(x, y, by = "id")
  expect_equal(diag$cardinality, "one-to-one")
})
