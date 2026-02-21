#' Initialize a Slitherlink grid
#'
#' Models the grid as an implicit graph using partial adjacency matrices.
#'
#' @param clues A numeric matrix containing the clues (0, 1, 2, 3, or NA).
#' @return An object of class 'slitherlink_grid' containing the edge matrices.
#' @export
init_grid <- function(clues) {
  if (!is.matrix(clues)) stop("The 'clues' argument must be a matrix.")

  n <- nrow(clues)
  m <- ncol(clues)

  # for horizontal segments matrix: (n+1) rows, m columns
  # for vertical segments matrix: n rows, (m+1) columns
  # the convention: 0 (empty), 1 (drawn), -1 (excluded/cross)
  seg_h <- matrix(0, nrow = n + 1, ncol = m)
  seg_v <- matrix(0, nrow = n, ncol = m + 1)

  structure(
    list(
      clues = clues,
      seg_h = seg_h,
      seg_v = seg_v,
      n = n,
      m = m
    ),
    class = "slitherlink_grid"
  )
}
#' Print a Slitherlink grid
#'
#' Custom print method to display the grid in the R console.
#'
#' @param x An object of class 'slitherlink_grid'.
#' @param ... Additional arguments (unused).
#' @export
print.slitherlink_grid <- function(x, ...) {
  cat("Slitherlink Grid (", x$n, "x", x$m, ")\n\n", sep = "")

  for (i in 1:x$n) {
    # Print intersections and horizontal segments using "+" and "x"
    for (j in 1:x$m) {
      cat("+")
      h_val <- x$seg_h[i, j]
      if (h_val == 1) cat("---")
      else if (h_val == -1) cat(" x ")
      else cat("   ")
    }
    cat("+\n")

    # Print vertical segments and clues using "|"
    for (j in 1:x$m) {
      v_val <- x$seg_v[i, j]
      if (v_val == 1) cat("| ")
      else if (v_val == -1) cat("x ")
      else cat("  ")

      clue <- x$clues[i, j]
      if (is.na(clue)) cat("  ")
      else cat(clue, " ")
    }

    # Last vertical segment of the row
    v_val_last <- x$seg_v[i, x$m + 1]
    if (v_val_last == 1) cat("|\n")
    else if (v_val_last == -1) cat("x\n")
    else cat(" \n")
  }

  # Print the bottom-most intersections and horizontal segments
  for (j in 1:x$m) {
    cat("+")
    h_val <- x$seg_h[x$n + 1, j]
    if (h_val == 1) cat("---")
    else if (h_val == -1) cat(" x ")
    else cat("   ")
  }
  cat("+\n")
}
