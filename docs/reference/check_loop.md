# Check if drawn segments form a single closed loop

Verifies the two topological conditions:

1.  Every node has degree 0 or 2 (no branches, no dead ends).

2.  All nodes with degree \> 0 are connected (single loop, not
    multiple).

## Usage

``` r
check_loop(grid)
```

## Arguments

- grid:

  An object of class 'slitherlink_grid'.

## Value

A logical value: TRUE if segments form a valid single closed loop.
