#' Generate a random solvable Slitherlink puzzle
#'
#' Creates a puzzle by first generating a random valid closed loop on an
#' n x m grid (via random region growth), then deriving the clue counts
#' from that loop.  Puzzles are verified to have a unique solution before
#' being returned; attempts that yield multiple solutions are discarded.
#'
#' @param n Integer. Number of rows (must be >= 2, default 5).
#' @param m Integer. Number of columns (must be >= 2, default 5).
#' @param seed Optional integer passed to \code{set.seed()} for
#'   reproducibility.
#' @param max_tries Maximum generation attempts before giving up
#'   (default 50).
#'
#' @return A \code{slitherlink_grid} with clues set and no segments drawn.
#' @export
random_puzzle <- function(n = 5L, m = 5L, seed = NULL,
                          max_tries = 50L) {
  n <- as.integer(n)
  m <- as.integer(m)
  if (n < 2L) stop("'n' must be >= 2.")
  if (m < 2L) stop("'m' must be >= 2.")

  if (!is.null(seed)) set.seed(seed)

  for (attempt in seq_len(max_tries)) {
    included <- random_region(n, m)

    # ---- derive loop from region boundary --------------------------------
    seg_h <- matrix(0L, n + 1L, m)
    seg_v <- matrix(0L, n, m + 1L)

    for (i in seq_len(n)) {
      for (j in seq_len(m)) {
        if (!included[i, j]) next
        # top edge: boundary if first row or upper neighbour not included
        if (i == 1L || !included[i - 1L, j])
          seg_h[i,      j] <- 1L
        # bottom edge
        if (i == n  || !included[i + 1L, j])
          seg_h[i + 1L, j] <- 1L
        # left edge
        if (j == 1L || !included[i, j - 1L])
          seg_v[i, j] <- 1L
        # right edge
        if (j == m  || !included[i, j + 1L])
          seg_v[i, j + 1L] <- 1L
      }
    }

    # ---- verify single closed loop ---------------------------------------
    tmp <- init_grid(matrix(NA_integer_, n, m))
    tmp$seg_h <- seg_h
    tmp$seg_v <- seg_v
    if (!check_loop(tmp)) next

    # ---- derive clues from boundary counts -------------------------------
    clues <- matrix(NA_integer_, n, m)
    for (i in seq_len(n)) {
      for (j in seq_len(m)) {
        clues[i, j] <-
          seg_h[i, j] + seg_h[i + 1L, j] +
          seg_v[i, j] + seg_v[i, j + 1L]
      }
    }

    # ---- reject if not uniquely solvable --------------------------------
    puzzle <- init_grid(clues)
    if (count_solutions(puzzle, max = 2L) != 1L) next

    return(puzzle)
  }

  stop(
    "Could not generate a valid random puzzle after ",
    max_tries, " attempts."
  )
}

# Internal helper: grow a random simply-connected region of cells.
# Returns a logical n x m matrix (TRUE = cell is inside the region).
random_region <- function(n, m) {
  lo     <- max(1L, as.integer(n * m * 0.3))
  hi     <- max(lo + 1L, as.integer(n * m * 0.7))
  target <- sample(lo:hi, 1L)

  included <- matrix(FALSE, n, m)
  si <- sample(seq_len(n), 1L)
  sj <- sample(seq_len(m), 1L)
  included[si, sj] <- TRUE

  # Frontier = cells already included that may still have free neighbours
  frontier <- list(c(si, sj))
  count    <- 1L

  dirs <- list(c(-1L, 0L), c(1L, 0L), c(0L, -1L), c(0L, 1L))

  while (length(frontier) > 0L && count < target) {
    idx  <- sample.int(length(frontier), 1L)
    ci   <- frontier[[idx]][1L]
    cj   <- frontier[[idx]][2L]

    # Try neighbours in random order
    order <- sample.int(4L)
    grew  <- FALSE
    for (k in order) {
      ni <- ci + dirs[[k]][1L]
      nj <- cj + dirs[[k]][2L]
      if (ni >= 1L && ni <= n &&
            nj >= 1L && nj <= m &&
            !included[ni, nj]) {
        included[ni, nj] <- TRUE
        frontier <- c(frontier, list(c(ni, nj)))
        count    <- count + 1L
        grew     <- TRUE
        break
      }
    }

    if (!grew) frontier[[idx]] <- NULL
  }

  included
}
