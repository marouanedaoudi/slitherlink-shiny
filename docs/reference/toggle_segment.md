# Toggle a segment in a Slitherlink grid

Cycles through states: 0 (empty) -\> 1 (drawn) -\> -1 (crossed) -\> 0.

## Usage

``` r
toggle_segment(grid, type, i, j)
```

## Arguments

- grid:

  An object of class 'slitherlink_grid'.

- type:

  Either "h" (horizontal) or "v" (vertical).

- i:

  Row index of the segment.

- j:

  Column index of the segment.

## Value

The updated 'slitherlink_grid' object.
