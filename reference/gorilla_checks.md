# Check Gorilla data for common problems

Lists participants and tasks that may need a closer look before the
analysis. Each row describes one finding. The function removes nothing,
so you decide what to exclude.

## Usage

``` r
gorilla_checks(
  x,
  fast = 200,
  max_fast = 0.1,
  max_same = 0.9,
  min_responses = 10,
  balance = 1.5
)
```

## Arguments

- x:

  A `gorilla_data` object from
  [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md).

- fast:

  Reaction time in milliseconds below which a response counts as fast.

- max_fast:

  Largest acceptable proportion of fast responses.

- max_same:

  Largest acceptable proportion of identical responses.

- min_responses:

  Fewest responses in a task for the `same_response` check to apply.

- balance:

  Largest acceptable ratio between the largest and the smallest group of
  a randomiser node.

## Value

A tibble with columns `check`, `participant_private_id`, `task_name` and
`detail`, with no rows if nothing was found.

## Details

The checks are

- status:

  Participants whose status is not `complete`, such as live or rejected
  participants included by hand. Skipped if the export has no status
  column.

- versions:

  Data from more than one version of the experiment.

- duplicate:

  The same public ID under several private IDs, which usually means that
  someone took part more than once.

- missing_task:

  Participants who did not do a task that most participants with the
  same outcomes of randomiser, branch, order, counterbalance and
  allocator nodes did.

- unbalanced:

  Randomiser nodes whose groups differ in size by more than the ratio
  `balance`.

- device:

  Participants who used a different type of device from most
  participants.

- fast:

  Participants with more than the proportion `max_fast` of responses in
  a task faster than `fast` milliseconds.

- same_response:

  Participants who gave the same response in more than the proportion
  `max_same` of at least `min_responses` responses in a task where other
  responses were possible. For components that recorded no response
  values, the object clicked or chosen counts as the response.

## See also

[`summary.gorilla_data()`](https://mcanzi.de/silverback/reference/summary.gorilla_data.md)
for an overview of each task.

## Examples

``` r
g <- read_gorilla(gorilla_example(), quiet = TRUE)
gorilla_checks(g)
#> # A tibble: 2 × 4
#>   check        participant_private_id task_name       detail                    
#>   <chr>        <chr>                  <chr>           <chr>                     
#> 1 status       9100222                NA              status is live            
#> 2 missing_task 9100222                Rhyme judgement not done, although 2 of 3…
```
