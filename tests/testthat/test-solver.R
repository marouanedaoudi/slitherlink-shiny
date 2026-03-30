test_that("solve_grid rejects non-grid input", {
  expect_error(solve_grid(list()), "'grid' must be a slitherlink_grid")
})

test_that("solve_grid: easy_3x3 returns a solved grid", {
  g <- get_puzzle("easy_3x3")
  sol <- solve_grid(g)
  expect_false(is.null(sol))
  expect_true(is_solved(sol))
})

test_that("solve_grid: medium_4x4 returns a solved grid", {
  g <- get_puzzle("medium_4x4")
  sol <- solve_grid(g)
  expect_false(is.null(sol))
  expect_true(is_solved(sol))
})

test_that("solve_grid: hard_5x5 returns a solved grid", {
  g <- get_puzzle("hard_5x5")
  sol <- solve_grid(g)
  expect_false(is.null(sol))
  expect_true(is_solved(sol))
})

test_that("solve_grid: unsolvable puzzle returns NULL", {
  # A 1x1 grid with clue 2: only possible loop uses all 4 edges (clue = 4)
  # so clue = 2 is impossible
  g <- init_grid(matrix(2L, 1, 1))
  expect_null(solve_grid(g))
})

test_that("solve_grid: already-solved grid is returned unchanged", {
  g <- solve_grid(get_puzzle("easy_3x3"))
  sol <- solve_grid(g)
  expect_true(is_solved(sol))
  expect_identical(g$seg_h, sol$seg_h)
  expect_identical(g$seg_v, sol$seg_v)
})
