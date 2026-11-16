# Questionnaire answers with one row per participant

Turns the questionnaire answers of
[`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md)
into a wide table with one row per participant and one column per item.
Items with a quantised value, such as the position of the chosen option
in a dropdown or a Likert scale, get a second column ending in
`_quantised`.

## Usage

``` r
gorilla_wide(x, task = NULL, quantised = TRUE)
```

## Arguments

- x:

  A `gorilla_data` object from
  [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md).

- task:

  Names of the questionnaires to include, as in the `task_name` column.
  All by default.

- quantised:

  Add the `_quantised` columns.

## Value

A tibble with `participant_private_id` and one column per item. Column
names are converted to snake case.

## Details

Questionnaires from Questionnaire Builder 1 and 2, downloaded in long or
short format, give the same columns. An item that appears in more than
one questionnaire gets the questionnaire name as a prefix. Objects of
Questionnaire Builder 2 that share a name within a questionnaire, such
as several objects left with the default name `Rating Scale`, are
different questions and get their object ID as a suffix, as in
`rating_scale_object_29`. If a participant answered the same item more
than once, for example after repeating a node or going back to a page,
the later answers go into columns ending in `__2`, `__3` and so on.
Cleaned item names never contain a double underscore, so these columns
cannot be confused with items whose names end in a number.

## Examples

``` r
g <- read_gorilla(gorilla_example())
#> Skipped 1 file without data (nodes no participant reached): data_exp_123456-v3_questionnaire-zz1e.csv
gorilla_wide(g)
#> # A tibble: 6 × 14
#>   participant_private_id   age gender gender_quantised languages_english
#>   <chr>                  <int> <chr>             <dbl>             <int>
#> 1 9100037                   23 Female                1                 1
#> 2 9100074                   34 Female                1                 1
#> 3 9100111                   22 Female                1                 1
#> 4 9100148                   26 Male                  2                 1
#> 5 9100185                   29 Female                1                 0
#> 6 9100222                   34 Male                  2                 0
#> # ℹ 9 more variables: languages_german <int>, languages_italian <int>,
#> #   languages_portuguese <int>, handedness <chr>, handedness_quantised <dbl>,
#> #   consent_data <chr>, consent_data_quantised <dbl>, consent_withdraw <chr>,
#> #   consent_withdraw_quantised <dbl>
```
