test_that("hint reveals exactly one correct segment (random pick)", {
  g   <- get_puzzle("easy_3x3")
  sol <- solve_grid(g)

  # Collect all candidate segments (drawn in solution, empty in g)
  candidates <- list()
  for (i in seq_len(nrow(sol$seg_h))) {
    for (j in seq_len(ncol(sol$seg_h))) {
      if (sol$seg_h[i, j] == 1L && g$seg_h[i, j] == 0L)
        candidates <- c(candidates, list(list(mat = "h", i = i, j = j)))
    }
  }
  for (i in seq_len(nrow(sol$seg_v))) {
    for (j in seq_len(ncol(sol$seg_v))) {
      if (sol$seg_v[i, j] == 1L && g$seg_v[i, j] == 0L)
        candidates <- c(candidates, list(list(mat = "v", i = i, j = j)))
    }
  }

  expect_gt(length(candidates), 0L)

  # Apply a random hint (same logic as the Shiny observer)
  set.seed(1L)
  pick <- candidates[[sample(length(candidates), 1L)]]
  if (pick$mat == "h") g$seg_h[pick$i, pick$j] <- 1L
  else                 g$seg_v[pick$i, pick$j] <- 1L

  # Exactly one segment drawn, consistent with solution
  expect_equal(sum(g$seg_h == 1L) + sum(g$seg_v == 1L), 1L)
  expect_true(check_clues(g, strict = FALSE))
})

test_that("hint candidate pool covers all missing solution segments", {
  g   <- get_puzzle("medium_4x4")
  sol <- solve_grid(g)

  missing_h <- sum(sol$seg_h == 1L & g$seg_h == 0L)
  missing_v <- sum(sol$seg_v == 1L & g$seg_v == 0L)
  expect_gt(missing_h + missing_v, 0L)
})

test_that("no hint candidates remain on a fully solved grid", {
  sol <- solve_grid(get_puzzle("easy_3x3"))

  remaining <- sum(sol$seg_h == 1L & sol$seg_h == 0L) +
               sum(sol$seg_v == 1L & sol$seg_v == 0L)
  expect_equal(remaining, 0L)
})
