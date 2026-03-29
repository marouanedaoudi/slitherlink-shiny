#' Check if all clues are satisfied
#'
#' Verifies the face constraints of the planar graph
#' For each cell with a numeric clue, the sum of its drawn boundary edges
#' must respect the clue
#'
#' @param grid An object of class 'slitherlink_grid'
#' @param strict If TRUE: drawn edges must exactly equal the clue
#'               If FALSE: drawn edges cannot exceed the clue (useful for ongoing games)
#' @return A logical value: TRUE if constraints are respected, FALSE otherwise
#' @export
check_clues <- function(grid, strict = FALSE) {
  n <- grid$n
  m <- grid$m

  for (i in 1:n) {
    for (j in 1:m) {
      clue <- grid$clues[i, j]

      # Skip cells without clues
      if (is.na(clue)) next

      # Count drawn edges (value == 1) around the cell (i, j)
      # Top edge
      top <- if (grid$seg_h[i, j] == 1) 1 else 0
      # Bottom edge
      bottom <- if (grid$seg_h[i + 1, j] == 1) 1 else 0
      # Left edge
      left <- if (grid$seg_v[i, j] == 1) 1 else 0
      # Right edge
      right <- if (grid$seg_v[i, j + 1] == 1) 1 else 0

      total_edges <- top + bottom + left + right

      # Validate based on the strictness level
      if (strict) {
        if (total_edges != clue) return(FALSE)
      } else {
        if (total_edges > clue) return(FALSE)
      }
    }
  }

  return(TRUE)
}
