# Generate a random solvable Slitherlink puzzle

Creates a puzzle by first generating a random valid closed loop on an n
x m grid (via random region growth), then deriving the clue counts from
that loop. The resulting grid has all segments reset to empty but
carries clues that are guaranteed to have at least one solution.

## Usage

``` r
random_puzzle(n = 5L, m = 5L, seed = NULL, max_tries = 50L)
```

## Arguments

- n:

  Integer. Number of rows (must be \>= 2, default 5).

- m:

  Integer. Number of columns (must be \>= 2, default 5).

- seed:

  Optional integer passed to
  [`set.seed()`](https://rdrr.io/r/base/Random.html) for
  reproducibility.

- max_tries:

  Maximum generation attempts before giving up (default 50).

## Value

A `slitherlink_grid` with clues set and no segments drawn.
