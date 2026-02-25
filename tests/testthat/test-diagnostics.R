# test-diagnostics.R

# key_status() tests -----------------------------------------------------------

test_that("key_status() returns correct structure for keyed data", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  status <- key_status(df)

  expect_s3_class(status, "keyed_status")
  expect_true(status$is_keyed)
  expect_equal(status$key_cols, "id")
  expect_equal(status$nrow, 3)
  expect_equal(status$ncol, 2)
  expect_true(status$key_valid)
  expect_equal(status$key_unique_count, 3)
  expect_equal(status$key_na_count, 0)
})

test_that("key_status() returns correct structure for unkeyed data", {
  df <- data.frame(id = 1:3, x = c("a", "b", "c"))
  status <- key_status(df)

  expect_s3_class(status, "keyed_status")
  expect_false(status$is_keyed)
  expect_null(status$key_cols)
})

test_that("key_status() detects duplicate keys", {
  df <- key(data.frame(id = c(1, 1, 2), x = c("a", "b", "c")), id, .validate = FALSE)
  status <- key_status(df)

  expect_false(status$key_valid)
  expect_equal(status$key_unique_count, 2)
})

test_that("key_status() detects NA in keys", {
  df <- key(data.frame(id = c(1, NA, 3), x = c("a", "b", "c")), id, .validate = FALSE)
  status <- key_status(df)

  expect_equal(status$key_na_count, 1)
})

test_that("key_status() detects missing key columns", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df$id <- NULL
  class(df) <- c("keyed_df", class(df))
  attr(df, "keyed_cols") <- "id"

  status <- key_status(df)
  expect_false(status$key_valid)
  expect_equal(status$key_missing_cols, "id")
})

test_that("key_status() detects row IDs", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df <- add_id(df)
  status <- key_status(df)

  expect_true(status$has_row_id)
})

test_that("key_status() detects snapshots", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df <- stamp(df)
  status <- key_status(df)

  expect_true(status$has_snapshot)
})

test_that("print.keyed_status() works", {
  df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  status <- key_status(df)

  # Just check it runs without error and returns invisibly

  expect_invisible(print(status))
})

test_that("print.keyed_status() handles invalid keys", {
  df <- key(data.frame(id = c(1, 1, 2), x = c("a", "b", "c")), id, .validate = FALSE)
  status <- key_status(df)

  expect_false(status$key_valid)
  expect_invisible(print(status))
})

test_that("print.keyed_status() handles no key", {
  df <- data.frame(id = 1:3, x = c("a", "b", "c"))
  status <- key_status(df)

  expect_false(status$is_keyed)
  expect_invisible(print(status))
})

# compare_structure() tests ----------------------------------------------------

test_that("compare_structure() detects identical structure", {
  df1 <- data.frame(id = 1:3, x = c("a", "b", "c"))
  df2 <- data.frame(id = 4:6, x = c("d", "e", "f"))
  comp <- compare_structure(df1, df2)

  expect_s3_class(comp, "keyed_structure_comparison")
  expect_true(comp$identical_structure)
  expect_equal(comp$nrow_diff, 0)
})

test_that("compare_structure() detects row count changes", {
  df1 <- data.frame(id = 1:3, x = c("a", "b", "c"))
  df2 <- data.frame(id = 1:5, x = letters[1:5])
  comp <- compare_structure(df1, df2)

  expect_equal(comp$nrow_diff, 2)
  # Note: identical_structure only tracks column/type changes, not row count
  expect_true(comp$identical_structure)
})

test_that("compare_structure() detects added columns", {
  df1 <- data.frame(id = 1:3, x = c("a", "b", "c"))
  df2 <- data.frame(id = 1:3, x = c("a", "b", "c"), y = 1:3)
  comp <- compare_structure(df1, df2)

  expect_equal(comp$cols_added, "y")
  expect_false(comp$identical_structure)
})

test_that("compare_structure() detects removed columns", {
  df1 <- data.frame(id = 1:3, x = c("a", "b", "c"), y = 1:3)
  df2 <- data.frame(id = 1:3, x = c("a", "b", "c"))
  comp <- compare_structure(df1, df2)

  expect_equal(comp$cols_removed, "y")
  expect_false(comp$identical_structure)
})

test_that("compare_structure() detects type changes", {
  df1 <- data.frame(id = 1:3, x = c("a", "b", "c"))
  df2 <- data.frame(id = as.character(1:3), x = c("a", "b", "c"))
  comp <- compare_structure(df1, df2)

  expect_equal(names(comp$type_changes), "id")
  expect_equal(comp$type_changes$id$from, "integer")
  expect_equal(comp$type_changes$id$to, "character")
})

test_that("compare_structure() detects key changes", {
  df1 <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
  df2 <- key(data.frame(id = 1:3, x = c("a", "b", "c")), x)
  comp <- compare_structure(df1, df2)

  expect_true(comp$key_changed)
})

test_that("print.keyed_structure_comparison() works", {
  df1 <- data.frame(id = 1:3, x = c("a", "b", "c"))
  df2 <- data.frame(id = 1:5, x = letters[1:5], y = 1:5)
  comp <- compare_structure(df1, df2)

  expect_invisible(print(comp))
})

# compare_keys() tests ---------------------------------------------------------

test_that("compare_keys() identifies common and different keys", {
  df1 <- key(data.frame(id = 1:3, x = 1:3), id)
  df2 <- key(data.frame(id = 2:4, x = 2:4), id)
  comp <- compare_keys(df1, df2)

  expect_s3_class(comp, "keyed_key_comparison")
  expect_equal(comp$n_common, 2)  # 2 and 3

  expect_equal(comp$n_only_x, 1)  # 1
  expect_equal(comp$n_only_y, 1)  # 4
})

test_that("compare_keys() works with explicit by", {
  df1 <- data.frame(id = 1:3, x = 1:3)
  df2 <- data.frame(id = 2:4, x = 2:4)
  comp <- compare_keys(df1, df2, by = "id")

  expect_equal(comp$by, "id")
  expect_equal(comp$n_common, 2)
})

test_that("compare_keys() errors without key or by", {
  df1 <- data.frame(id = 1:3, x = 1:3)
  df2 <- data.frame(id = 2:4, x = 2:4)

  expect_error(compare_keys(df1, df2), "No key defined")
})

test_that("compare_keys() errors on missing columns", {
  df1 <- key(data.frame(id = 1:3, x = 1:3), id)
  df2 <- data.frame(other = 2:4, x = 2:4)

  expect_error(compare_keys(df1, df2), "not found in y")
})

test_that("compare_keys() handles empty overlap", {
  df1 <- key(data.frame(id = 1:3, x = 1:3), id)
  df2 <- key(data.frame(id = 4:6, x = 4:6), id)
  comp <- compare_keys(df1, df2)

  expect_equal(comp$n_common, 0)
  expect_equal(comp$overlap_pct, 0)
})

test_that("print.keyed_key_comparison() works", {
  df1 <- key(data.frame(id = 1:3, x = 1:3), id)
  df2 <- key(data.frame(id = 2:4, x = 2:4), id)
  comp <- compare_keys(df1, df2)

  expect_invisible(print(comp))
  expect_equal(comp$n_common, 2)
})

# find_duplicates() tests ------------------------------------------------------

test_that("find_duplicates() finds duplicate keys", {
  df <- data.frame(id = c(1, 1, 2, 3, 3, 3), x = letters[1:6])
  result <- find_duplicates(df, id)

  expect_equal(nrow(result), 5)  # 2 rows for id=1, 3 rows for id=3
  expect_true(".n" %in% names(result))
})

test_that("find_duplicates() uses key columns when available", {
  df <- key(data.frame(id = c(1, 1, 2, 3, 3, 3), x = letters[1:6]), id, .validate = FALSE)
  result <- find_duplicates(df)

  expect_equal(nrow(result), 5)
})

test_that("find_duplicates() returns empty when no duplicates", {
  df <- data.frame(id = 1:3, x = letters[1:3])
  expect_message(result <- find_duplicates(df, id), "No duplicates")
  expect_equal(nrow(result), 0)
})

test_that("find_duplicates() errors without columns or key", {
  df <- data.frame(id = 1:3, x = letters[1:3])
  expect_error(find_duplicates(df), "No columns specified")
})

test_that("find_duplicates() works with composite keys", {
  df <- data.frame(
    a = c(1, 1, 1, 2),
    b = c(1, 1, 2, 1),
    x = letters[1:4]
  )
  result <- find_duplicates(df, a, b)

  expect_equal(nrow(result), 2)  # Only the (1, 1) pair is duplicated
})
