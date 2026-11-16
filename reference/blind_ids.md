# Replace participant identifiers

Replaces the public identifiers that can link participants to a
recruitment platform, such as Prolific or SONA IDs, with codes such as
`P001`. The same participant gets the same code in all tables. The
private identifiers assigned by 'Gorilla' are kept, because they do not
identify anyone outside 'Gorilla'. Answers that participants typed in,
such as an ID entered in a questionnaire, are not changed.

## Usage

``` r
blind_ids(
  x,
  columns = c("participant_public_id", "participant_external_session_id",
    "participant_completion_code")
)
```

## Arguments

- x:

  A `gorilla_data` object from
  [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md).

- columns:

  Columns to replace. By default the public ID, the external session ID
  and the completion code.

## Value

`x` with the identifiers replaced. Participants without a value keep
`NA`.

## Examples

``` r
g <- read_gorilla(gorilla_example())
#> Skipped 1 file without data (nodes no participant reached): data_exp_123456-v3_questionnaire-zz1e.csv
gorilla_participants(blind_ids(g))
#> # A tibble: 6 × 18
#>   participant_private_id participant_public_id experiment_id
#>   <chr>                  <chr>                         <int>
#> 1 9100037                P001                         123456
#> 2 9100074                P002                         123456
#> 3 9100111                P003                         123456
#> 4 9100148                P004                         123456
#> 5 9100185                P005                         123456
#> 6 9100222                P006                         123456
#> # ℹ 15 more variables: participant_device_type <chr>, participant_device <chr>,
#> #   participant_os <chr>, participant_browser <chr>,
#> #   participant_monitor_size <chr>, participant_viewport_size <chr>,
#> #   local_timezone <int>, experiment_version <int>, participant_status <chr>,
#> #   start <dttm>, end <dttm>, tasks <int>, randomiser_ab12 <chr>,
#> #   store_score <int>, minutes <dbl>
```
