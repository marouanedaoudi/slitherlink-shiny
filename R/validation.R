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

#' Check if drawn segments form a single closed loop
#'
#' Verifies the two topological conditions:
#' 1. Every node has degree 0 or 2 (no branches, no dead ends).
#' 2. All nodes with degree > 0 are connected (single loop, not multiple).
#'
#' @param grid An object of class 'slitherlink_grid'.
#' @return A logical value: TRUE if segments form a valid single closed loop.
#' @export
check_loop <- function(grid) {
  n <- grid$n
  m <- grid$m

  # Nodes are the (n+1) x (m+1) intersections, indexed as (i, j)
  # Encode node (i, j) as a single integer: (i-1)*(m+1) + j
  node_id <- function(i, j) (i - 1L) * (m + 1L) + j

  # Build adjacency list and degree count
  num_nodes <- (n + 1L) * (m + 1L)
  degree <- integer(num_nodes)
  adj <- vector("list", num_nodes)

  add_edge <- function(a, b) {
    degree[a] <<- degree[a] + 1L
    degree[b] <<- degree[b] + 1L
    adj[[a]] <<- c(adj[[a]], b)
    adj[[b]] <<- c(adj[[b]], a)
  }

  # Horizontal segments: seg_h[i, j] connects node (i,j) -- (i, j+1)
  for (i in 1:(n + 1)) {
    for (j in 1:m) {
      if (grid$seg_h[i, j] == 1L) {
        add_edge(node_id(i, j), node_id(i, j + 1L))
      }
    }
  }

  # Vertical segments: seg_v[i, j] connects node (i,j) -- (i+1, j)
  for (i in 1:n) {
    for (j in 1:(m + 1)) {
      if (grid$seg_v[i, j] == 1L) {
        add_edge(node_id(i, j), node_id(i + 1L, j))
      }
    }
  }

  # No segments drawn at all — not a valid loop
  if (all(degree == 0L)) return(FALSE)

  # Condition 1: every active node must have degree exactly 2
  if (any(degree != 0L & degree != 2L)) return(FALSE)

  # Condition 2: all active nodes are connected (BFS)
  active <- which(degree > 0L)
  visited <- logical(num_nodes)
  queue <- active[1L]
  visited[queue] <- TRUE

  while (length(queue) > 0L) {
    current <- queue[1L]
    queue <- queue[-1L]
    for (nb in adj[[current]]) {
      if (!visited[nb]) {
        visited[nb] <- TRUE
        queue <- c(queue, nb)
      }
    }
  }

  all(visited[active])
}

#' Check if a Slitherlink grid is fully solved
#'
#' A grid is solved when all clue constraints are exactly satisfied
#' and the drawn segments form a single closed loop.
#'
#' @param grid An object of class 'slitherlink_grid'.
#' @return A logical value: TRUE if the puzzle is solved.
#' @export
is_solved <- function(grid) {
  check_clues(grid, strict = TRUE) && check_loop(grid)
}
