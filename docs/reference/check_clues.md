# Check if all clues are satisfied

Verifies the face constraints of the planar graph For each cell with a
numeric clue, the sum of its drawn boundary edges must respect the clue

## Usage

``` r
check_clues(grid, strict = FALSE)
```

## Arguments

- grid:

  An object of class 'slitherlink_grid'

- strict:

  If TRUE: drawn edges must exactly equal the clue If FALSE: drawn edges
  cannot exceed the clue (useful for ongoing games)

## Value

A logical value: TRUE if constraints are respected, FALSE otherwise
