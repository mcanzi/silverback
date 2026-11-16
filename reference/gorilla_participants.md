# Participants

One row per participant, with the identifiers, the status, the device,
operating system and browser, and the times of the first and last
recorded event. `tasks` counts the tasks and questionnaires the
participant has data for. The outcome of each randomiser, branch and
checkpoint node follows, and then the last value of each store field.
Columns that are empty for all participants are dropped.

## Usage

``` r
gorilla_participants(x, status = NULL)
```

## Arguments

- x:

  A `gorilla_data` object from
  [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md).

- status:

  Keep only participants with these values of `participant_status`, such
  as `"complete"`. All by default.

## Value

A tibble. `start` and `end` are in UTC; `minutes` is the time between
them.

## Examples

``` r
g <- read_gorilla(gorilla_example())
#> Skipped 1 file without data (nodes no participant reached): data_exp_123456-v3_questionnaire-zz1e.csv
gorilla_participants(g)
#> # A tibble: 6 × 18
#>   participant_private_id participant_public_id    experiment_id
#>   <chr>                  <chr>                            <int>
#> 1 9100037                c805ceab3f4eb9172ecd0b95        123456
#> 2 9100074                1d1c4b74f2b229c3711cbcc8        123456
#> 3 9100111                b48c18f6af1d44ac3fe078e2        123456
#> 4 9100148                cce8638538eef07b5c3ce7a5        123456
#> 5 9100185                7f50b2600354023e074434c0        123456
#> 6 9100222                9b2d42c0a5c131039b4134ea        123456
#> # ℹ 15 more variables: participant_device_type <chr>, participant_device <chr>,
#> #   participant_os <chr>, participant_browser <chr>,
#> #   participant_monitor_size <chr>, participant_viewport_size <chr>,
#> #   local_timezone <int>, experiment_version <int>, participant_status <chr>,
#> #   start <dttm>, end <dttm>, tasks <int>, randomiser_ab12 <chr>,
#> #   store_score <int>, minutes <dbl>
```
