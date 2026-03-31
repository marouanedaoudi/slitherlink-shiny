# Check if a grid state contains a contradiction

Returns TRUE if any constraint is already violated, i.e. the current
partial assignment cannot lead to a valid solution. Checks: clue
overflows, node degree \> 2, and premature loops.

## Usage

``` r
has_contradiction(grid)
```

## Arguments

- grid:

  An object of class 'slitherlink_grid'.

## Value

TRUE if a contradiction exists, FALSE otherwise.
