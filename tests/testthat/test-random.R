test_that("random_puzzle returns a slitherlink_grid", {
  g <- random_puzzle(seed = 1L)
  expect_s3_class(g, "slitherlink_grid")
})

test_that("random_puzzle has correct dimensions", {
  g <- random_puzzle(n = 4L, m = 6L, seed = 7L)
  expect_equal(g$n, 4L)
  expect_equal(g$m, 6L)
})

test_that("random_puzzle starts with all segments empty", {
  g <- random_puzzle(seed = 2L)
  expect_true(all(g$seg_h == 0L))
  expect_true(all(g$seg_v == 0L))
})

test_that("random_puzzle clues are integers between 0 and 4", {
  g <- random_puzzle(seed = 3L)
  expect_true(all(g$clues >= 0L & g$clues <= 4L))
})

test_that("random_puzzle is solvable", {
  g   <- random_puzzle(seed = 42L)
  sol <- solve_grid(g)
  expect_false(is.null(sol))
  expect_true(is_solved(sol))
})

test_that("random_puzzle is reproducible with same seed", {
  g1 <- random_puzzle(n = 5L, m = 5L, seed = 99L)
  g2 <- random_puzzle(n = 5L, m = 5L, seed = 99L)
  expect_equal(g1$clues, g2$clues)
})

test_that("random_puzzle differs across seeds", {
  g1 <- random_puzzle(seed = 1L)
  g2 <- random_puzzle(seed = 2L)
  # Very unlikely to produce identical clue matrices
  expect_false(identical(g1$clues, g2$clues))
})

test_that("random_puzzle rejects n < 2", {
  expect_error(random_puzzle(n = 1L), "'n' must be >= 2")
})

test_that("random_puzzle rejects m < 2", {
  expect_error(random_puzzle(m = 1L), "'m' must be >= 2")
})

test_that("random_puzzle works for 2x2 grid", {
  g <- random_puzzle(n = 2L, m = 2L, seed = 5L)
  expect_s3_class(g, "slitherlink_grid")
  expect_false(is.null(solve_grid(g)))
})
