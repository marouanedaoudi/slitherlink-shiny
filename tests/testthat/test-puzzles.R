test_that("list_puzzles returns a data frame with required columns", {
  df <- list_puzzles()
  expect_s3_class(df, "data.frame")
  expect_true(all(c("name", "difficulty", "size", "verified") %in% names(df)))
  expect_gt(nrow(df), 0L)
})

test_that("get_puzzle returns a slitherlink_grid", {
  g <- get_puzzle("easy_3x3")
  expect_s3_class(g, "slitherlink_grid")
  expect_equal(g$n, 3L)
  expect_equal(g$m, 3L)
})

test_that("get_puzzle: all listed puzzles load without error", {
  for (nm in list_puzzles()$name) {
    expect_no_error(get_puzzle(nm))
  }
})

test_that("get_puzzle: unknown name throws error", {
  expect_error(get_puzzle("nonexistent_puzzle"), "Unknown puzzle")
})

test_that("get_puzzle returns grid with all segments zeroed", {
  g <- get_puzzle("medium_4x4")
  expect_true(all(g$seg_h == 0L))
  expect_true(all(g$seg_v == 0L))
})
