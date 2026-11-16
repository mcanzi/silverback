# Summarise Gorilla data

Describes each task and questionnaire in one row, as a first check of
the data after reading them.

## Usage

``` r
# S3 method for class 'gorilla_data'
summary(object, fast = 200, slow = 10000, ...)
```

## Arguments

- object:

  A `gorilla_data` object from
  [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md).

- fast, slow:

  Reaction times in milliseconds below `fast` or above `slow` are
  counted as fast or slow responses.

- ...:

  Not used.

## Value

An object of class `gorilla_summary`: a list with two tibbles.

- tasks:

  One row per task: builder, number of participants, number of responses
  per participant (minimum, median and maximum), the proportion of
  responses marked as correct, the median reaction time, the proportions
  of fast and slow responses and the median time participants spent on
  the task, in minutes. The proportion correct only means something for
  tasks with scoring set up in 'Gorilla': components without scoring
  mark every response as correct, and rating scales count a response as
  correct only if it matches the answer column of the spreadsheet.

- questionnaires:

  One row per questionnaire: number of participants, number of items and
  the proportion of items left unanswered.

## See also

[`gorilla_checks()`](https://mcanzi.de/silverback/reference/gorilla_checks.md)
to list participants who may need a closer look.

## Examples

``` r
g <- read_gorilla(gorilla_example(), quiet = TRUE)
summary(g)
#> 6 participants (complete: 5, live: 1)
#> 
#> Tasks
#>         task_name        builder participants responses_min responses_median
#>  Lexical decision Task Builder 2            6             7               16
#>   Rhyme judgement Task Builder 1            5             8                8
#>  responses_max correct rt_median fast slow minutes
#>             16   0.943     673.1    0    0     0.4
#>              8   0.950     910.1    0    0     0.4
#> 
#> Questionnaires
#>   task_name participants items unanswered
#>  Background            6     7          0
#>     Consent            6     2          0
summary(g)$tasks
#> # A tibble: 2 × 11
#>   task_name    builder participants responses_min responses_median responses_max
#>   <chr>        <chr>          <int>         <int>            <dbl>         <int>
#> 1 Lexical dec… Task B…            6             7               16            16
#> 2 Rhyme judge… Task B…            5             8                8             8
#> # ℹ 5 more variables: correct <dbl>, rt_median <dbl>, fast <dbl>, slow <dbl>,
#> #   minutes <dbl>
```
