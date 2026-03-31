# Introduction to slitherlinkshiny

## What is Slitherlink?

Slitherlink is a logic puzzle played on a rectangular grid of dots. The
goal is to draw segments between adjacent dots to form a **single closed
loop** — no branches, no crossings, no loose ends.

Numbers inside cells indicate exactly how many of the cell’s four edges
belong to the loop. Cells without a number are unconstrained.

    +   +   +   +
      2   1   2
    +   +   +   +
      1   0   1
    +   +   +   +
      2   1   2
    +   +   +   +

The unique solution for the 3×3 puzzle above is the outer rectangle.

------------------------------------------------------------------------

## Grid representation

The package stores a puzzle as a `slitherlink_grid` object with three
components:

| Field   | Dimensions | Meaning                    |
|---------|------------|----------------------------|
| `clues` | n × m      | Clue values (NA = no clue) |
| `seg_h` | (n+1) × m  | Horizontal segment states  |
| `seg_v` | n × (m+1)  | Vertical segment states    |

Each segment is one of three integer values:

| Value | Meaning |
|-------|---------|
| `0`   | Empty   |
| `1`   | Drawn   |
| `-1`  | Crossed |

------------------------------------------------------------------------

## Creating a grid

Use
[`init_grid()`](https://marouanedaoudi.github.io/slitherlink-shiny/reference/init_grid.md)
to build a grid from a clue matrix. `NA` marks cells with no constraint.

``` r

library(slitherlinkshiny)

clues <- matrix(
  c(2, 1, 2,
    1, 0, 1,
    2, 1, 2),
  nrow = 3, byrow = TRUE
)
g <- init_grid(clues)
print(g)
#> Slitherlink Grid (3x3)
#> 
#> +   +   +   +
#>   2    1    2   
#> +   +   +   +
#>   1    0    1   
#> +   +   +   +
#>   2    1    2   
#> +   +   +   +
```

------------------------------------------------------------------------

## Predefined puzzles

The package ships with three ready-to-play puzzles.

``` r

list_puzzles()
#>                  name difficulty size verified
#> easy_3x3     easy_3x3       easy  3x3     TRUE
#> medium_4x4 medium_4x4     medium  4x4     TRUE
#> hard_5x5     hard_5x5       hard  5x5     TRUE
```

Load one with
[`get_puzzle()`](https://marouanedaoudi.github.io/slitherlink-shiny/reference/get_puzzle.md):

``` r

g <- get_puzzle("medium_4x4")
print(g)
#> Slitherlink Grid (4x4)
#> 
#> +   +   +   +   +
#>   2    2    2    1   
#> +   +   +   +   +
#>   1    1    2    3   
#> +   +   +   +   +
#>   2    2    1    1   
#> +   +   +   +   +
#>   3    1    0    0   
#> +   +   +   +   +
```

------------------------------------------------------------------------

## Toggling segments

[`toggle_segment()`](https://marouanedaoudi.github.io/slitherlink-shiny/reference/toggle_segment.md)
cycles a segment through the three states: `0 → 1 → -1 → 0`.

- `type = "h"` targets a horizontal segment at row `i`, column `j` (row
  index counts from top; `i` ranges from 1 to n+1).
- `type = "v"` targets a vertical segment (`i` from 1 to n, `j` from 1
  to m+1).

``` r

g <- get_puzzle("easy_3x3")

# Draw the top edge of cell (1,1): horizontal segment h[1,1]
g <- toggle_segment(g, type = "h", i = 1, j = 1)
g$seg_h[1, 1]   # now 1 (drawn)
#> [1] 1

# Draw it again to cross it
g <- toggle_segment(g, type = "h", i = 1, j = 1)
g$seg_h[1, 1]   # now -1 (crossed)
#> [1] -1

# Draw it once more to reset
g <- toggle_segment(g, type = "h", i = 1, j = 1)
g$seg_h[1, 1]   # back to 0 (empty)
#> [1] 0
```

------------------------------------------------------------------------

## Validating the state

Three functions check the current state of the grid.

### `check_clues()`

Verifies that no clue constraint is violated.

- `strict = FALSE` (default for in-progress play): drawn edges must not
  *exceed* the clue.
- `strict = TRUE`: drawn edges must *exactly equal* the clue.

``` r

g <- get_puzzle("easy_3x3")
check_clues(g, strict = FALSE)   # TRUE  — nothing drawn yet
#> [1] TRUE
check_clues(g, strict = TRUE)    # FALSE — no clue is exactly matched
#> [1] FALSE
```

### `check_loop()`

Returns `TRUE` if the drawn segments form a single valid closed loop
(every active node has degree exactly 2, and all active nodes are
connected).

``` r

check_loop(g)   # FALSE — no segments drawn
#> [1] FALSE
```

### `is_solved()`

A puzzle is solved when both `check_clues(strict = TRUE)` and
[`check_loop()`](https://marouanedaoudi.github.io/slitherlink-shiny/reference/check_loop.md)
return `TRUE`.

``` r

is_solved(g)   # FALSE
#> [1] FALSE
```

------------------------------------------------------------------------

## Solving a puzzle automatically

[`solve_grid()`](https://marouanedaoudi.github.io/slitherlink-shiny/reference/solve_grid.md)
uses constraint propagation followed by backtracking to find the unique
solution.

``` r

g   <- get_puzzle("easy_3x3")
sol <- solve_grid(g)
print(sol)
#> Slitherlink Grid (3x3)
#> 
#> +---+---+---+
#> | 2  x 1  x 2  |
#> + x + x + x +
#> | 1  x 0  x 1  |
#> + x + x + x +
#> | 2  x 1  x 2  |
#> +---+---+---+
is_solved(sol)
#> [1] TRUE
```

The solver works on all three built-in puzzles:

``` r

for (nm in list_puzzles()$name) {
  sol <- solve_grid(get_puzzle(nm))
  cat(nm, "→ solved:", is_solved(sol), "\n")
}
#> easy_3x3 → solved: TRUE 
#> medium_4x4 → solved: TRUE 
#> hard_5x5 → solved: TRUE
```

If the puzzle has no valid solution,
[`solve_grid()`](https://marouanedaoudi.github.io/slitherlink-shiny/reference/solve_grid.md)
returns `NULL`:

``` r

impossible <- init_grid(matrix(2L, 1, 1))  # clue 2 in a 1x1 grid: impossible
is.null(solve_grid(impossible))
#> [1] TRUE
```

------------------------------------------------------------------------

## Interactive Shiny app

The package includes a full interactive web application. Launch it from
the R console:

``` r

run_app()
```

Features:

- **Select puzzle** — choose from the built-in library.
- **New Game / Reset** — load or restart the selected puzzle.
- **Click segments** — click near any edge to cycle its state (empty →
  drawn → crossed → empty).
- **Solve** — fill in the complete solution instantly.
- **Status indicator** — shows *In progress*, *Constraint violated*, or
  *Puzzle solved!* in real time.
