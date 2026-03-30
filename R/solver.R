# ============================================================
# Slitherlink solver: constraint propagation + backtracking
# ============================================================

# ------ Helper: get the 4 edges of a cell (i, j) -----------

# Returns a list with named elements: top, bottom, left, right
# Each is a list(matrix = "h"/"v", row = r, col = c)
cell_edges <- function(i, j) {
  list(
    top    = list(mat = "h", row = i,     col = j),
    bottom = list(mat = "h", row = i + 1, col = j),
    left   = list(mat = "v", row = i,     col = j),
    right  = list(mat = "v", row = i,     col = j + 1)
  )
}

# ------ Helper: get the 4 edges of a node (i, j) -----------

# Returns a list of edge descriptors that touch this node.
# Node (i, j) is the intersection point; edges from it:
#   horizontal left  : h[i, j-1]  (if j > 1)
#   horizontal right : h[i, j]    (if j <= m)
#   vertical   up    : v[i-1, j]  (if i > 1)
#   vertical   down  : v[i, j]    (if i <= n)
node_edges <- function(i, j, n, m) {
  edges <- list()
  if (j > 1)  edges <- c(edges, list(list(mat = "h", row = i,     col = j - 1)))
  if (j <= m) edges <- c(edges, list(list(mat = "h", row = i,     col = j)))
  if (i > 1)  edges <- c(edges, list(list(mat = "v", row = i - 1, col = j)))
  if (i <= n) edges <- c(edges, list(list(mat = "v", row = i,     col = j)))
  edges
}

# ------ Helper: read/write a segment by descriptor ---------

get_seg <- function(grid, e) {
  if (e$mat == "h") grid$seg_h[e$row, e$col]
  else               grid$seg_v[e$row, e$col]
}

set_seg <- function(grid, e, val) {
  if (e$mat == "h") grid$seg_h[e$row, e$col] <- val
  else               grid$seg_v[e$row, e$col] <- val
  grid
}

# ------ Contradiction detection ----------------------------

#' Check if a grid state contains a contradiction
#'
#' Returns TRUE if any constraint is already violated, i.e. the
#' current partial assignment cannot lead to a valid solution.
#' Checks: clue overflows, node degree > 2, and premature loops.
#'
#' @param grid An object of class 'slitherlink_grid'.
#' @return TRUE if a contradiction exists, FALSE otherwise.
has_contradiction <- function(grid) {
  n <- grid$n
  m <- grid$m

  # --- Cell constraint violation ---
  for (i in 1:n) {
    for (j in 1:m) {
      clue <- grid$clues[i, j]
      if (is.na(clue)) next
      edges <- cell_edges(i, j)
      drawn   <- sum(sapply(edges, function(e) get_seg(grid, e) ==  1L))
      crossed <- sum(sapply(edges, function(e) get_seg(grid, e) == -1L))
      # Too many drawn edges
      if (drawn > clue) return(TRUE)
      # Remaining undecided edges cannot reach the clue
      if (drawn + (4L - drawn - crossed) < clue) return(TRUE)
    }
  }

  # --- Node degree violation + premature loop detection ---
  node_id <- function(i, j) (i - 1L) * (m + 1L) + j
  num_nodes <- (n + 1L) * (m + 1L)
  degree <- integer(num_nodes)
  adj    <- vector("list", num_nodes)

  for (i in 1:(n + 1L)) {
    for (j in 1:m) {
      if (grid$seg_h[i, j] == 1L) {
        a <- node_id(i, j); b <- node_id(i, j + 1L)
        degree[a] <- degree[a] + 1L; degree[b] <- degree[b] + 1L
        adj[[a]] <- c(adj[[a]], b);  adj[[b]] <- c(adj[[b]], a)
      }
    }
  }
  for (i in 1:n) {
    for (j in 1:(m + 1L)) {
      if (grid$seg_v[i, j] == 1L) {
        a <- node_id(i, j); b <- node_id(i + 1L, j)
        degree[a] <- degree[a] + 1L; degree[b] <- degree[b] + 1L
        adj[[a]] <- c(adj[[a]], b);  adj[[b]] <- c(adj[[b]], a)
      }
    }
  }

  # Any node with degree > 2 is invalid
  if (any(degree > 2L)) return(TRUE)

  # Detect premature loop: a closed sub-loop that doesn't use ALL drawn edges.
  # A premature loop exists when a connected component of drawn edges is already
  # a valid loop (all nodes degree-2) but there are other drawn edges elsewhere.
  active <- which(degree > 0L)
  if (length(active) > 0L) {
    total_drawn_edges <- (sum(grid$seg_h == 1L) + sum(grid$seg_v == 1L))
    # BFS from first active node
    visited <- logical(num_nodes)
    queue <- active[1L]; visited[queue] <- TRUE
    while (length(queue) > 0L) {
      cur <- queue[1L]; queue <- queue[-1L]
      for (nb in adj[[cur]])
        if (!visited[nb]) { visited[nb] <- TRUE; queue <- c(queue, nb) }
    }
    component <- which(visited)
    # If this component forms a closed loop (all degree 2) but doesn't account
    # for all drawn edges, it is a premature sub-loop
    if (all(degree[component] == 2L)) {
      component_edges <- sum(degree[component]) / 2L
      if (component_edges < total_drawn_edges) return(TRUE)
    }
  }

  FALSE
}

# ------ Constraint propagation: cell rules -----------------

# Apply cell-level deduction rules once over the whole grid.
# Returns the updated grid (possibly with more segments decided).
apply_cell_rules <- function(grid) {
  n <- grid$n; m <- grid$m

  for (i in 1:n) {
    for (j in 1:m) {
      clue <- grid$clues[i, j]
      if (is.na(clue)) next

      edges   <- cell_edges(i, j)
      drawn   <- sum(sapply(edges, function(e) get_seg(grid, e) ==  1L))
      crossed <- sum(sapply(edges, function(e) get_seg(grid, e) == -1L))
      free    <- 4L - drawn - crossed

      if (free == 0L) next  # already fully decided

      # drawn == clue  =>  cross all free edges
      if (drawn == clue) {
        for (e in edges)
          if (get_seg(grid, e) == 0L) grid <- set_seg(grid, e, -1L)
      }

      # drawn + free == clue  =>  draw all free edges
      if (drawn + free == clue) {
        for (e in edges)
          if (get_seg(grid, e) == 0L) grid <- set_seg(grid, e, 1L)
      }
    }
  }

  grid
}

# ------ Constraint propagation: node rules -----------------

# Apply node-level deduction rules once over the whole grid.
apply_node_rules <- function(grid) {
  n <- grid$n; m <- grid$m

  for (i in 1:(n + 1L)) {
    for (j in 1:(m + 1L)) {
      edges  <- node_edges(i, j, n, m)
      drawn  <- sum(sapply(edges, function(e) get_seg(grid, e) ==  1L))
      crossed <- sum(sapply(edges, function(e) get_seg(grid, e) == -1L))
      free   <- length(edges) - drawn - crossed

      if (free == 0L) next

      # Node already has 2 drawn edges: cross all remaining
      if (drawn == 2L) {
        for (e in edges)
          if (get_seg(grid, e) == 0L) grid <- set_seg(grid, e, -1L)
      }

      # Node has 1 drawn edge and only 1 free slot: must draw it
      # (because a node in a loop needs exactly 0 or 2 drawn edges;
      #  if it already has 1 it must eventually reach 2)
      # NOTE: we only apply this when there is exactly 1 free edge left,
      # to avoid drawing edges too aggressively and creating contradictions.
      if (drawn == 1L && free == 1L) {
        for (e in edges)
          if (get_seg(grid, e) == 0L) grid <- set_seg(grid, e, 1L)
      }
    }
  }

  grid
}

# ------ Full propagation loop ------------------------------

#' Propagate constraints until no more deductions can be made
#'
#' Repeatedly applies cell and node rules until the grid stabilises
#' (fixpoint) or a contradiction is detected.
#'
#' @param grid An object of class 'slitherlink_grid'.
#' @return A list with two elements:
#'   \item{grid}{The updated grid after propagation.}
#'   \item{contradiction}{TRUE if a contradiction was found.}
propagate <- function(grid) {
  repeat {
    prev_h <- grid$seg_h
    prev_v <- grid$seg_v

    grid <- apply_cell_rules(grid)
    grid <- apply_node_rules(grid)

    if (has_contradiction(grid))
      return(list(grid = grid, contradiction = TRUE))

    # Fixpoint: nothing changed this iteration
    if (identical(grid$seg_h, prev_h) && identical(grid$seg_v, prev_v))
      break
  }

  list(grid = grid, contradiction = FALSE)
}

# ------ Backtracking search --------------------------------

# Internal recursive backtracker.
# Returns a solved grid or NULL if no solution exists from this state.
backtrack <- function(grid) {
  # Propagate first
  result <- propagate(grid)
  if (result$contradiction) return(NULL)
  grid <- result$grid

  # Check if already solved
  if (is_solved(grid)) return(grid)

  # Pick the first undecided segment (value == 0)
  # Try horizontal segments first, then vertical
  chosen <- NULL
  for (i in seq_len(nrow(grid$seg_h))) {
    for (j in seq_len(ncol(grid$seg_h))) {
      if (grid$seg_h[i, j] == 0L) {
        chosen <- list(mat = "h", row = i, col = j)
        break
      }
    }
    if (!is.null(chosen)) break
  }
  if (is.null(chosen)) {
    for (i in seq_len(nrow(grid$seg_v))) {
      for (j in seq_len(ncol(grid$seg_v))) {
        if (grid$seg_v[i, j] == 0L) {
          chosen <- list(mat = "v", row = i, col = j)
          break
        }
      }
      if (!is.null(chosen)) break
    }
  }

  # All segments decided but not solved (shouldn't happen after propagation
  # without contradiction, but guard anyway)
  if (is.null(chosen)) return(NULL)

  # Try drawing the chosen segment
  candidate <- set_seg(grid, chosen, 1L)
  solution  <- backtrack(candidate)
  if (!is.null(solution)) return(solution)

  # Try crossing the chosen segment
  candidate <- set_seg(grid, chosen, -1L)
  solution  <- backtrack(candidate)
  if (!is.null(solution)) return(solution)

  NULL
}

# ------ Public entry point ---------------------------------

#' Solve a Slitherlink puzzle
#'
#' Attempts to find the unique solution to a Slitherlink puzzle using
#' constraint propagation followed by backtracking search.
#'
#' @param grid An object of class 'slitherlink_grid' with all segments
#'   in their initial state (all zeros, as returned by \code{init_grid}
#'   or \code{get_puzzle}).
#' @return The solved \code{slitherlink_grid} object, or \code{NULL} if
#'   no solution exists.
#' @export
solve_grid <- function(grid) {
  if (!inherits(grid, "slitherlink_grid"))
    stop("'grid' must be a slitherlink_grid object.")
  backtrack(grid)
}
