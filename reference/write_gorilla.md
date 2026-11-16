# Write tidy data to CSV files

Writes the tidy tables to a folder of CSV files, for analysis in other
software or for sharing. The folder gets up to four files:
`participants.csv` from
[`gorilla_participants()`](https://mcanzi.de/silverback/reference/gorilla_participants.md),
`trials.csv` from
[`gorilla_trials()`](https://mcanzi.de/silverback/reference/gorilla_trials.md),
and `questionnaires.csv` from
[`gorilla_wide()`](https://mcanzi.de/silverback/reference/gorilla_wide.md)
with one row per participant. `questionnaires_long.csv` has the
questionnaire answers with one row per answer, as in `x$questionnaires`.
Files for data the export does not have are not written.

## Usage

``` r
write_gorilla(x, path, by_task = FALSE, overwrite = FALSE)
```

## Arguments

- x:

  A `gorilla_data` object from
  [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md).

- path:

  Folder to write to. It is created if it does not exist.

- by_task:

  Write the trials of each task to its own file, named after the task,
  instead of one `trials.csv`.

- overwrite:

  Replace files that already exist in `path`.

## Value

The paths of the written files, invisibly.

## Details

The files are UTF-8 with a comma as separator. Missing values are left
empty, and times are written in ISO 8601 format in UTC. The exports
contain the identifiers Gorilla collected, so use
[`blind_ids()`](https://mcanzi.de/silverback/reference/blind_ids.md)
first if the files will be shared.

## Examples

``` r
g <- read_gorilla(gorilla_example())
#> Skipped 1 file without data (nodes no participant reached): data_exp_123456-v3_questionnaire-zz1e.csv
out <- file.path(tempdir(), "gorilla_csv")
files <- write_gorilla(g, out)
basename(files)
#> [1] "participants.csv"        "trials.csv"             
#> [3] "questionnaires.csv"      "questionnaires_long.csv"
readr::read_csv(files[1], show_col_types = FALSE)
#> # A tibble: 6 × 18
#>   participant_private_id participant_public_id    experiment_id
#>                    <dbl> <chr>                            <dbl>
#> 1                9100037 c805ceab3f4eb9172ecd0b95        123456
#> 2                9100074 1d1c4b74f2b229c3711cbcc8        123456
#> 3                9100111 b48c18f6af1d44ac3fe078e2        123456
#> 4                9100148 cce8638538eef07b5c3ce7a5        123456
#> 5                9100185 7f50b2600354023e074434c0        123456
#> 6                9100222 9b2d42c0a5c131039b4134ea        123456
#> # ℹ 15 more variables: participant_device_type <chr>, participant_device <chr>,
#> #   participant_os <chr>, participant_browser <chr>,
#> #   participant_monitor_size <chr>, participant_viewport_size <chr>,
#> #   local_timezone <dbl>, experiment_version <dbl>, participant_status <chr>,
#> #   start <dttm>, end <dttm>, tasks <dbl>, randomiser_ab12 <chr>,
#> #   store_score <dbl>, minutes <dbl>
unlink(out, recursive = TRUE)
```
