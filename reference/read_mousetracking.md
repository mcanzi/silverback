# Read mouse tracking data

Reads the files that the Mouse Tracking component of Task Builder 2
saves for each trial. 'Gorilla' does not put these recordings in the
main export but in files of their own, named like
`123456-3-9100037-task-ab12-50000037-mousetracking-10-2.csv`.

## Usage

``` r
read_mousetracking(path, x = NULL, zones = NULL, quiet = FALSE)
```

## Arguments

- path:

  Paths to folders, CSV files or ZIP archives. Folders and ZIP archives
  are searched recursively for files whose names contain
  `-mousetracking-`. CSV files named directly are read whatever their
  name.

- x:

  Optional `gorilla_data` object from
  [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md)
  of the same experiment, used to add the task and screen names.

- zones:

  Names of the zones to assign samples to. All by default.

- quiet:

  If `TRUE`, no message about files that could not be used is shown.

## Value

An object of class `gorilla_mousetracking`: a list with

- mouse:

  One row per sample, with the participant, node, task, spreadsheet,
  trial and screen, the kind of sample (`type`, usually `"mouse"`), a
  timer of the browser in milliseconds (`timestamp`, not a date), the
  time since the start of the recording in milliseconds (`elapsed`), the
  position of the pointer (`x`, `y`, `x_raw`, `y_raw`) and the zone it
  is in (`zone_id`, `zone_name`).

- zones:

  One row per zone and recording, with the object ID (`zone_id`), the
  name, and the edges `left`, `right`, `bottom` and `top` in normalised
  coordinates.

- files:

  One row per file read, with its kind and number of rows.

## Details

Positions are given in normalised coordinates: `0` to `1` across the
area of the task, with the origin at the bottom left, as in the export.
Raw coordinates in pixels are kept as `x_raw` and `y_raw`; in these, as
recorded by the browser, `y` counts from the top of the window.

Each sample is assigned to the zone of the screen it falls in. When
zones overlap, the smallest zone containing the sample wins. Use `zones`
to test only some zones.

The recordings do not say which task they belong to. Pass the main
export as `x` to add `task_name`, so that the samples can be joined to
[`gorilla_trials()`](https://mcanzi.de/silverback/reference/gorilla_trials.md)
by `participant_private_id`, `tree_node_key`, `display`, `trial` and
`screen`.

## See also

[`read_eyetracking()`](https://mcanzi.de/silverback/reference/read_eyetracking.md)
for the Eye Tracking component.

## Examples

``` r
if (FALSE) { # \dontrun{
g <- read_gorilla("data")
mouse <- read_mousetracking("data", x = g)
mouse$mouse
} # }
```
