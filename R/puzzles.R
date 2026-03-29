# Predefined Slitherlink puzzle library
#
# Each puzzle is stored as a named list with:
#   - difficulty : "easy", "medium", or "hard"
#   - size       : human-readable grid dimensions
#   - clues      : numeric matrix (NA = no clue for that cell)
#
# Puzzles marked with verified = TRUE have been checked to have a unique
# valid solution matching the loop and clue constraints.

PUZZLES <- list(

  # 3x3 — solution: outer rectangle
  # Verified: all border edges drawn, interior empty
  easy_3x3 = list(
    difficulty = "easy",
    size       = "3x3",
    verified   = TRUE,
    clues      = matrix(
      c(2, 1, 2,
        1, 0, 1,
        2, 1, 2),
      nrow = 3, byrow = TRUE
    )
  ),

  # 4x4 — solution: custom L-shaped loop
  # Verified by manual segment tracing
  medium_4x4 = list(
    difficulty = "medium",
    size       = "4x4",
    verified   = TRUE,
    clues      = matrix(
      c(2, 2, 2, 1,
        1, 1, 2, 3,
        2, 2, 1, 1,
        3, 1, 0, 0),
      nrow = 4, byrow = TRUE
    )
  ),

  # 5x5 — based on the example from the project specification
  hard_5x5 = list(
    difficulty = "hard",
    size       = "5x5",
    verified   = FALSE,
    clues      = matrix(
      c( 2,  2, NA, NA, NA,
        NA, NA,  3,  2, NA,
        NA, NA, NA, NA,  1,
         3,  0, NA, NA,  2,
        NA,  3,  2,  2, NA),
      nrow = 5, byrow = TRUE
    )
  )
)

#' List available predefined puzzles
#'
#' @return A data frame with puzzle names, difficulty, and size.
#' @export
list_puzzles <- function() {
  data.frame(
    name       = names(PUZZLES),
    difficulty = vapply(PUZZLES, `[[`, character(1), "difficulty"),
    size       = vapply(PUZZLES, `[[`, character(1), "size"),
    verified   = vapply(PUZZLES, `[[`, logical(1),   "verified"),
    stringsAsFactors = FALSE
  )
}

#' Load a predefined puzzle as a slitherlink_grid
#'
#' @param name A string matching one of the names returned by list_puzzles().
#' @return An object of class 'slitherlink_grid' ready to play.
#' @export
get_puzzle <- function(name) {
  if (!name %in% names(PUZZLES)) {
    stop(sprintf(
      "Unknown puzzle '%s'. Available puzzles: %s",
      name, paste(names(PUZZLES), collapse = ", ")
    ))
  }
  init_grid(PUZZLES[[name]]$clues)
}
