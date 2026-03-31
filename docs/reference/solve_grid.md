# Solve a Slitherlink puzzle

Attempts to find the unique solution to a Slitherlink puzzle using
constraint propagation followed by backtracking search.

## Usage

``` r
solve_grid(grid)
```

## Arguments

- grid:

  An object of class 'slitherlink_grid' with all segments in their
  initial state (all zeros, as returned by `init_grid` or `get_puzzle`).

## Value

The solved `slitherlink_grid` object, or `NULL` if no solution exists.
