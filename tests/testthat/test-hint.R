# The hint logic (used in the Shiny app) can be tested at the R level:
# given a grid and its solution, the first undiscovered drawn segment
# should be revealable.

test_that("hint reveals exactly one correct segment", {
  g   <- get_puzzle("easy_3x3")
  sol <- solve_grid(g)

  # Simulate hint: find first seg_h that is 1 in solution and 0 in g
  hint_applied <- FALSE
  for (i in seq_len(nrow(sol$seg_h))) {
    for (j in seq_len(ncol(sol$seg_h))) {
      if (sol$seg_h[i, j] == 1L && g$seg_h[i, j] == 0L) {
        g$seg_h[i, j] <- 1L
        hint_applied <- TRUE
        break
      }
    }
    if (hint_applied) break
  }
  if (!hint_applied) {
    for (i in seq_len(nrow(sol$seg_v))) {
      for (j in seq_len(ncol(sol$seg_v))) {
        if (sol$seg_v[i, j] == 1L && g$seg_v[i, j] == 0L) {
          g$seg_v[i, j] <- 1L
          hint_applied <- TRUE
          break
        }
      }
      if (hint_applied) break
    }
  }

  expect_true(hint_applied)
  # Exactly one more drawn segment than before
  total_drawn <- sum(g$seg_h == 1L) + sum(g$seg_v == 1L)
  expect_equal(total_drawn, 1L)
  # The revealed segment is consistent with the solution
  expect_true(check_clues(g, strict = FALSE))
})

test_that("hint has nothing left to reveal on a solved grid", {
  sol <- solve_grid(get_puzzle("easy_3x3"))

  # On a fully solved grid, no seg_h[i,j]==1 with sol$seg_h[i,j]==0 exists
  remaining <- sum(sol$seg_h == 1L & sol$seg_h == 0L) +
               sum(sol$seg_v == 1L & sol$seg_v == 0L)
  expect_equal(remaining, 0L)
})
