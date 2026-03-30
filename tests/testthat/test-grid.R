test_that("init_grid creates correct structure", {
  clues <- matrix(c(1, 2, 3, 0), nrow = 2)
  g <- init_grid(clues)

  expect_s3_class(g, "slitherlink_grid")
  expect_equal(g$n, 2L)
  expect_equal(g$m, 2L)
  expect_equal(dim(g$seg_h), c(3L, 2L))
  expect_equal(dim(g$seg_v), c(2L, 3L))
  expect_true(all(g$seg_h == 0L))
  expect_true(all(g$seg_v == 0L))
})

test_that("init_grid rejects non-matrix input", {
  expect_error(init_grid(c(1, 2, 3)), "'clues' argument must be a matrix")
})

test_that("toggle_segment cycles h: 0 -> 1 -> -1 -> 0", {
  g <- init_grid(matrix(1, 1, 1))
  expect_equal(g$seg_h[1, 1], 0L)

  g <- toggle_segment(g, "h", 1, 1)
  expect_equal(g$seg_h[1, 1], 1L)

  g <- toggle_segment(g, "h", 1, 1)
  expect_equal(g$seg_h[1, 1], -1L)

  g <- toggle_segment(g, "h", 1, 1)
  expect_equal(g$seg_h[1, 1], 0L)
})

test_that("toggle_segment cycles v: 0 -> 1 -> -1 -> 0", {
  g <- init_grid(matrix(1, 1, 1))

  g <- toggle_segment(g, "v", 1, 1)
  expect_equal(g$seg_v[1, 1], 1L)

  g <- toggle_segment(g, "v", 1, 1)
  expect_equal(g$seg_v[1, 1], -1L)

  g <- toggle_segment(g, "v", 1, 1)
  expect_equal(g$seg_v[1, 1], 0L)
})

test_that("toggle_segment rejects out-of-bounds indices", {
  g <- init_grid(matrix(0, 2, 2))
  expect_error(toggle_segment(g, "h", 0, 1))
  expect_error(toggle_segment(g, "h", 4, 1))  # n+1 = 3 max
  expect_error(toggle_segment(g, "v", 1, 0))
  expect_error(toggle_segment(g, "v", 1, 4))  # m+1 = 3 max
})

test_that("toggle_segment rejects non-grid input", {
  expect_error(toggle_segment(list(), "h", 1, 1))
})
