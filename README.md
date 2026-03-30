# slitherlinkshiny

An R package implementing the [Slitherlink](https://en.wikipedia.org/wiki/Slitherlink) logic puzzle, with an interactive Shiny web application.

## What is Slitherlink?

Slitherlink is a logic puzzle played on a grid of dots. The goal is to draw segments between adjacent dots to form a **single closed loop** with no branches or crossings. Numbers inside cells indicate exactly how many of the cell's four edges belong to the loop.

## Installation

```r
# Install dependencies
install.packages(c("shiny", "devtools"))

# Load the package from source
devtools::load_all()
```

## Usage

### Launch the app

```r
run_app()
```

### Use the library directly

```r
# Create a grid from a clue matrix (NA = no clue)
clues <- matrix(c(2, 1, 2,
                  1, 0, 1,
                  2, 1, 2), nrow = 3, byrow = TRUE)
g <- init_grid(clues)

# Or load a predefined puzzle
list_puzzles()       # show available puzzles
g <- get_puzzle("medium_4x4")

# Toggle a segment (cycles: empty -> drawn -> crossed -> empty)
g <- toggle_segment(g, type = "h", i = 1, j = 1)  # horizontal
g <- toggle_segment(g, type = "v", i = 1, j = 1)  # vertical

# Validate the current state
check_clues(g)              # are all clue constraints satisfied? (non-strict)
check_clues(g, strict=TRUE) # exact match required
check_loop(g)               # do segments form a single closed loop?
is_solved(g)                # full solution check (clues + loop)

print(g)                    # console display
```

## Package structure

```
R/
  grid.R        # init_grid(), toggle_segment(), print.slitherlink_grid()
  validation.R  # check_clues(), check_loop(), is_solved()
  puzzles.R     # list_puzzles(), get_puzzle()
  app.R         # run_app()
inst/
  shiny/
    app.R       # Shiny application
```

## Predefined puzzles

| Name          | Difficulty | Size | Verified |
|---------------|------------|------|----------|
| `easy_3x3`   | Easy       | 3×3  | Yes      |
| `medium_4x4` | Medium     | 4×4  | Yes      |
| `hard_5x5`   | Hard       | 5×5  | No       |

## Segment states

Each segment on the grid can be in one of three states:

| Value | Meaning  | Display        |
|-------|----------|----------------|
| `0`   | Empty    | Gray dashed    |
| `1`   | Drawn    | Black solid    |
| `-1`  | Crossed  | Red ×          |

## Grid representation

The grid is stored as a `slitherlink_grid` object containing:
- `clues` — `n × m` matrix of clue values
- `seg_h` — `(n+1) × m` matrix of horizontal segments
- `seg_v` — `n × (m+1)` matrix of vertical segments
