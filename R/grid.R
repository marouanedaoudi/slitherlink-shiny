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
