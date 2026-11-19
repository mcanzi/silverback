# Read eye tracking data

Reads the files that the Eye Tracking (Webgazer) component of Task
Builder 2 saves for each trial. 'Gorilla' does not put these recordings
in the main export but in files of their own, named like
`123456-3-9100037-task-ab12-50000037-collection-10-2.csv` (gaze) and
`...-calibration-1-2.csv` (calibration).

## Usage

``` r
read_eyetracking(path, x = NULL, zones = NULL, quiet = FALSE)
```

## Arguments

- path:

  Paths to folders, CSV files or ZIP archives. Folders and ZIP archives
  are searched recursively for files whose names contain `-collection-`
  or `-calibration-`. CSV files named directly are read whatever their
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

An object of class `gorilla_eyetracking`: a list with

- gaze:

  One row per gaze sample, with the participant, node, task,
  spreadsheet, trial and screen, the kind of sample (`type`, usually
  `"prediction"`), the time of the sample in UTC (`time`), the time
  since the start of the recording in milliseconds (`elapsed`), the
  predicted gaze position (`x`, `y`, `x_raw`, `y_raw`) and the zone it
  falls in (`zone_id`, `zone_name`).

- zones:

  One row per zone and recording, with the object ID (`zone_id`), the
  name, and the edges `left`, `right`, `bottom` and `top` in normalised
  coordinates.

- calibration:

  One row per calibration point and attempt, with the outcome of the
  attempt (`"succeeded"`, `"failed - retrying"` or
  `"failed - max failures"`), the position of the point, the centre and
  standard deviation of the gaze predictions while the participant
  looked at it, and `error`, the distance between point and centre, all
  in normalised coordinates. Attempts that ended before any point was
  measured have one row with missing point values.

- files:

  One row per file read, with its kind and number of rows.

## Details

Positions are given in normalised coordinates: `0` to `1` across the
area of the task, with the origin at the bottom left, as in the export.
Raw coordinates in pixels are kept as `x_raw` and `y_raw`, but they
depend on the participant's screen. Predictions outside the area of the
task, below `0` or above `1`, are kept; webcam eye tracking produces
them when participants look away or the prediction is poor.

Each gaze sample is assigned to the zone of the screen it falls in. When
zones overlap, the smallest zone containing the sample wins. Use `zones`
to test only some zones, for example the pictures of a visual world task
and not the response buttons placed on them.

The recordings do not say which task they belong to or, for gaze data,
the name of the screen. Pass the main export as `x` to add `task_name`
and `screen`, so that the samples can be joined to
[`gorilla_trials()`](https://mcanzi.de/silverback/reference/gorilla_trials.md)
by `participant_private_id`, `tree_node_key`, `display`, `trial` and
`screen`.

## See also

[`read_mousetracking()`](https://mcanzi.de/silverback/reference/read_mousetracking.md)
for the Mouse Tracking component.

## Examples

``` r
g <- read_gorilla(gorilla_example(), quiet = TRUE)
eye <- read_eyetracking(gorilla_example(), x = g)
eye
#> <gorilla_eyetracking>
#> 48 gaze samples from 1 participant in 3 recordings; 43.8% in a zone
#> 1 calibration attempt (succeeded: 1)
eye$gaze
#> # A tibble: 48 × 20
#>    participant_private_id experiment_version tree_node_key task_name spreadsheet
#>    <chr>                               <dbl> <chr>         <chr>     <chr>      
#>  1 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#>  2 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#>  3 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#>  4 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#>  5 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#>  6 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#>  7 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#>  8 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#>  9 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#> 10 9100037                                 3 task-ld2k     Lexical … Spreadshee…
#> # ℹ 38 more rows
#> # ℹ 15 more variables: spreadsheet_index <dbl>, display <chr>, trial <dbl>,
#> #   screen <chr>, screen_id <chr>, file <chr>, type <chr>, time <dttm>,
#> #   elapsed <dbl>, x <dbl>, y <dbl>, x_raw <dbl>, y_raw <dbl>, zone_id <chr>,
#> #   zone_name <chr>
eye$calibration
#> # A tibble: 5 × 20
#>   participant_private_id experiment_version tree_node_key task_name  spreadsheet
#>   <chr>                               <dbl> <chr>         <chr>      <chr>      
#> 1 9100037                                 3 task-ld2k     Lexical d… Spreadshee…
#> 2 9100037                                 3 task-ld2k     Lexical d… Spreadshee…
#> 3 9100037                                 3 task-ld2k     Lexical d… Spreadshee…
#> 4 9100037                                 3 task-ld2k     Lexical d… Spreadshee…
#> 5 9100037                                 3 task-ld2k     Lexical d… Spreadshee…
#> # ℹ 15 more variables: spreadsheet_index <dbl>, display <chr>, trial <dbl>,
#> #   screen <chr>, screen_id <chr>, attempt <int>, outcome <chr>, file <chr>,
#> #   point_x <dbl>, point_y <dbl>, centroid_x <dbl>, centroid_y <dbl>,
#> #   sd_x <dbl>, sd_y <dbl>, error <dbl>
table(eye$gaze$trial, eye$gaze$zone_name, useNA = "ifany")
#>    
#>     Word <NA>
#>   1    7    9
#>   2    4   12
#>   3   10    6
```
