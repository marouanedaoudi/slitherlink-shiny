# Initialize a Slitherlink grid

Models the grid as an implicit graph using partial adjacency matrices.

## Usage

``` r
init_grid(clues)
```

## Arguments

- clues:

  A numeric matrix containing the clues (0, 1, 2, 3, or NA).

## Value

An object of class 'slitherlink_grid' containing the edge matrices.
