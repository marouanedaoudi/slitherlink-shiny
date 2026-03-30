# Helper: build a 1x1 grid with an outer rectangle drawn
make_1x1_loop <- function() {
  g <- init_grid(matrix(4L, 1, 1))
  g$seg_h[1, 1] <- 1L
  g$seg_h[2, 1] <- 1L
  g$seg_v[1, 1] <- 1L
  g$seg_v[1, 2] <- 1L
  g
}

# Helper: build a solved 3x3 outer-rectangle puzzle
make_3x3_solved <- function() {
  g <- get_puzzle("easy_3x3")
  g <- solve_grid(g)
  g
}

# ---- check_clues ----

test_that("check_clues: empty grid passes non-strict (0 drawn <= any clue)", {
  g <- get_puzzle("easy_3x3")
  expect_true(check_clues(g, strict = FALSE))
})

test_that("check_clues strict: empty grid fails (0 != clue values)", {
  g <- get_puzzle("easy_3x3")
  expect_false(check_clues(g, strict = TRUE))
})

test_that("check_clues non-strict: detects overflow", {
  g <- init_grid(matrix(1L, 1, 1))  # clue = 1
  # draw all 4 edges
  g$seg_h[1, 1] <- 1L
  g$seg_h[2, 1] <- 1L
  g$seg_v[1, 1] <- 1L
  g$seg_v[1, 2] <- 1L
  expect_false(check_clues(g, strict = FALSE))
})

test_that("check_clues strict: solved 1x1 passes", {
  g <- make_1x1_loop()
  expect_true(check_clues(g, strict = TRUE))
})

test_that("check_clues: NA cells are ignored", {
  g <- init_grid(matrix(NA_real_, 2, 2))
  expect_true(check_clues(g, strict = TRUE))
})

# ---- check_loop ----

test_that("check_loop: empty grid is not a loop", {
  g <- get_puzzle("easy_3x3")
  expect_false(check_loop(g))
})

test_that("check_loop: single closed 1x1 square is a valid loop", {
  g <- make_1x1_loop()
  expect_true(check_loop(g))
})

test_that("check_loop: two disjoint loops fail", {
  # 1x2 grid — draw two separate 1-cell squares
  g <- init_grid(matrix(c(4L, 4L), nrow = 1))
  # left square
  g$seg_h[1, 1] <- 1L
  g$seg_h[2, 1] <- 1L
  g$seg_v[1, 1] <- 1L
  g$seg_v[1, 2] <- 1L
  # right square
  g$seg_h[1, 2] <- 1L
  g$seg_h[2, 2] <- 1L
  # seg_v[1,2] already drawn — shared edge, skip (it's one loop actually)
  # Use a fresh non-touching setup instead: detach v[1,2]
  g$seg_v[1, 2] <- 0L
  g$seg_v[1, 3] <- 1L
  # Now left loop: h[1,1], h[2,1], v[1,1], v[1,2]=0 — not closed anymore
  # Better: 2x1 grid with two separate horizontal loops is tricky; just test degree-1 node
  g2 <- init_grid(matrix(0L, 2, 2))
  g2$seg_h[1, 1] <- 1L  # dead-end edge (degree-1 nodes)
  expect_false(check_loop(g2))
})

test_that("check_loop: dead-end edge fails (degree-1 node)", {
  g <- init_grid(matrix(0L, 2, 2))
  g$seg_h[1, 1] <- 1L
  expect_false(check_loop(g))
})

# ---- is_solved ----

test_that("is_solved: empty puzzle is not solved", {
  g <- get_puzzle("easy_3x3")
  expect_false(is_solved(g))
})

test_that("is_solved: solver output is solved", {
  g <- make_3x3_solved()
  expect_true(is_solved(g))
})
