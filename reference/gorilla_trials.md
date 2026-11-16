# Responses in task data

Keeps the rows of the task data that hold a participant's response and
gives them the same columns whether the task was made with Task Builder
1 or 2. Rows with instructions, continue buttons, fixation crosses,
media events and other information are dropped.

## Usage

``` r
gorilla_trials(x, task = NULL, all_rows = FALSE)
```

## Arguments

- x:

  A `gorilla_data` object from
  [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md).

- task:

  Names of the tasks to include, as in the `task_name` column. All by
  default.

- all_rows:

  Keep all rows of the trials, not only the responses. A column
  `response_type` then says what each row is, such as `"response"`,
  `"info"` or a zone type.

## Value

A tibble with one row per response and columns

- participant_private_id, experiment_version, tree_node_key, repeat_key,
  task_name, task_version:

  Who did which task, in which version and node of the experiment, with
  Gorilla's Repeat Key.

- spreadsheet:

  Name of the spreadsheet used.

- trial:

  Trial number.

- display, screen:

  Display and screen of the response. Task Builder 1 has no displays.

- component, object:

  Component and object that recorded the response in Task Builder 2;
  zone type and zone name in Task Builder 1.

- response:

  The response, as text.

- rt:

  Reaction time in milliseconds.

- correct:

  Whether the response was scored as correct.

- time:

  Time of the response, in UTC.

followed by the timing columns of the export, such as `reaction_onset`
in Task Builder 1 or `onset_time`, `absolute_reaction_time` and
`response_duration` in Task Builder 2, and by the spreadsheet
(`spreadsheet_`) and store (`store_`) columns. Only columns with values
for the selected tasks are kept. All columns of the export remain in
`x$tasks`.

## Details

In Task Builder 2 a response is a row with `response_type` `"response"`.
In Task Builder 1 it is a row from a response zone (`zone_type` starting
with `response_`).

## Examples

``` r
g <- read_gorilla(gorilla_example())
#> Skipped 1 file without data (nodes no participant reached): data_exp_123456-v3_questionnaire-zz1e.csv
gorilla_trials(g)
#> # A tibble: 127 × 23
#>    participant_private_id experiment_version tree_node_key repeat_key task_name 
#>    <chr>                               <int> <chr>         <chr>      <chr>     
#>  1 9100037                                 3 task-ld2k     NA         Lexical d…
#>  2 9100037                                 3 task-ld2k     NA         Lexical d…
#>  3 9100037                                 3 task-ld2k     NA         Lexical d…
#>  4 9100037                                 3 task-ld2k     NA         Lexical d…
#>  5 9100037                                 3 task-ld2k     NA         Lexical d…
#>  6 9100037                                 3 task-ld2k     NA         Lexical d…
#>  7 9100037                                 3 task-ld2k     NA         Lexical d…
#>  8 9100037                                 3 task-ld2k     NA         Lexical d…
#>  9 9100037                                 3 task-ld2k     NA         Lexical d…
#> 10 9100037                                 3 task-ld2k     NA         Lexical d…
#> # ℹ 117 more rows
#> # ℹ 18 more variables: task_version <int>, spreadsheet <chr>, trial <dbl>,
#> #   display <chr>, screen <chr>, component <chr>, object <chr>, response <chr>,
#> #   rt <dbl>, correct <lgl>, time <dttm>, spreadsheet_word <chr>,
#> #   spreadsheet_lexicality <chr>, spreadsheet_answer <chr>,
#> #   spreadsheet_row <int>, spreadsheet_word_1 <chr>, spreadsheet_word_2 <chr>,
#> #   spreadsheet_rhyme <chr>
gorilla_trials(g, task = "Lexical decision")
#> # A tibble: 87 × 19
#>    participant_private_id experiment_version tree_node_key repeat_key task_name 
#>    <chr>                               <int> <chr>         <chr>      <chr>     
#>  1 9100037                                 3 task-ld2k     NA         Lexical d…
#>  2 9100037                                 3 task-ld2k     NA         Lexical d…
#>  3 9100037                                 3 task-ld2k     NA         Lexical d…
#>  4 9100037                                 3 task-ld2k     NA         Lexical d…
#>  5 9100037                                 3 task-ld2k     NA         Lexical d…
#>  6 9100037                                 3 task-ld2k     NA         Lexical d…
#>  7 9100037                                 3 task-ld2k     NA         Lexical d…
#>  8 9100037                                 3 task-ld2k     NA         Lexical d…
#>  9 9100037                                 3 task-ld2k     NA         Lexical d…
#> 10 9100037                                 3 task-ld2k     NA         Lexical d…
#> # ℹ 77 more rows
#> # ℹ 14 more variables: task_version <int>, spreadsheet <chr>, trial <dbl>,
#> #   display <chr>, screen <chr>, component <chr>, object <chr>, response <chr>,
#> #   rt <dbl>, correct <lgl>, time <dttm>, spreadsheet_word <chr>,
#> #   spreadsheet_lexicality <chr>, spreadsheet_answer <chr>
```
