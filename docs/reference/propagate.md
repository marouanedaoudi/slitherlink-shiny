# Propagate constraints until no more deductions can be made

Repeatedly applies cell and node rules until the grid stabilises
(fixpoint) or a contradiction is detected.

## Usage

``` r
propagate(grid)
```

## Arguments

- grid:

  An object of class 'slitherlink_grid'.

## Value

A list with two elements:

- grid:

  The updated grid after propagation.

- contradiction:

  TRUE if a contradiction was found.
