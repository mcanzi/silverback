# Getting started with silverback

silverback turns the files you download from the Gorilla Experiment
Builder into three tidy tibbles: one for task responses, one for
questionnaire answers and one for participants. A typical session looks
like this:

``` r

library(silverback)

g <- read_gorilla("data_exp_123456-v3.zip")
gorilla_checks(g)
trials <- gorilla_trials(g)
answers <- gorilla_wide(g)
people <- gorilla_participants(g)
write_gorilla(g, "tidy")
```

The rest of this page goes through each step with a small invented
experiment that comes with the package.

``` r

library(silverback)
library(dplyr, warn.conflicts = FALSE)
```

## Download the data from Gorilla

On the Data tab of your experiment, generate the data for the versions
you need and download it. Gorilla offers two layouts, one file per node
of the experiment tree or combined files with all tasks in one file and
all questionnaires in another. Either works as long as you choose CSV.
Questionnaires can be downloaded in long or short format.

Unzip the download or leave it as it is.
[`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md)
accepts the ZIP file, the folder or single CSV files. Keep one layout
per folder: with both, the same rows would be read twice, and
[`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md)
warns about it.

## Read the files

The example experiment has a lexical decision task made with Task
Builder 2, a rhyme judgement task made with Task Builder 1, a consent
form made with Questionnaire Builder 1 and a background questionnaire
made with Questionnaire Builder 2. One branch of the experiment was
never reached, so one of the files is empty.

``` r

g <- read_gorilla(gorilla_example())
#> Skipped 1 file without data (nodes no participant reached): data_exp_123456-v3_questionnaire-zz1e.csv
g
#> <gorilla_data> experiment 123456, version 3
#> 6 participants
#>   complete: 5, live: 1
#> Tasks:
#>   Lexical decision (Task Builder 2): 6 participants
#>   Rhyme judgement (Task Builder 1): 5 participants
#> Questionnaires:
#>   Background: 7 items, 6 participants
#>   Consent: 2 items, 6 participants
#> 1 empty file skipped
```

The printout lists the tasks and questionnaires that were found and how
many participants did each. Empty files are skipped with a message.

[`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md)
returns a list of four tables. `g$files` has one row per file and says
which builder each file comes from. `g$tasks` keeps every row of every
task file, `g$questionnaires` holds one row per questionnaire answer and
`g$participants` one row per participant. You will rarely need the first
two directly.

``` r

g$files
#> # A tibble: 5 × 8
#>   file                        experiment version node  kind  builder task   rows
#>   <chr>                       <chr>      <chr>   <chr> <chr> <chr>   <chr> <int>
#> 1 data_exp_123456-v3_questio… 123456     3       ques… ques… questi… Back…    66
#> 2 data_exp_123456-v3_questio… 123456     3       ques… ques… questi… Cons…    36
#> 3 data_exp_123456-v3_questio… 123456     3       ques… ques… questi… NA        0
#> 4 data_exp_123456-v3_task-ld… 123456     3       task… task  task_b… Lexi…   104
#> 5 data_exp_123456-v3_task-rh… 123456     3       task… task  task_b… Rhym…    90
```

Column names are converted to snake case, so `Participant Private ID`
becomes `participant_private_id`. Columns that come from your
spreadsheets start with `spreadsheet_`, and values saved to the store
start with `store_`. Task Builder 1 exports give spreadsheet columns no
prefix at all, and silverback adds it so that both builders look the
same.

## Check the data

Before the analysis it is worth looking at what came in.
[`summary()`](https://rdrr.io/r/base/summary.html) gives one line per
task and questionnaire:

``` r

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
```

For tasks, the line shows how many responses each participant gave, the
share Gorilla marked as correct, the median reaction time and how long
people spent on the task. That share only means something if scoring was
set up in Gorilla. For questionnaires, it shows how many items were left
unanswered.

[`gorilla_checks()`](https://mcanzi.de/silverback/reference/gorilla_checks.md)
goes further and lists findings about single participants:

``` r

gorilla_checks(g)
#> # A tibble: 2 × 4
#>   check        participant_private_id task_name       detail                    
#>   <chr>        <chr>                  <chr>           <chr>                     
#> 1 status       9100222                NA              status is live            
#> 2 missing_task 9100222                Rhyme judgement not done, although 2 of 3…
```

In the example one participant stopped during the lexical decision task.
The checks report the status and the missing rhyme judgement task. On
real data they also find people who took part twice under the same
public ID, who pressed the same key almost every time, who often
answered faster than 200 ms, or who used a different type of device from
most participants. Randomiser groups of very different sizes are
reported too. You can change the thresholds with the function’s
arguments. Nothing is removed, so you decide what to exclude.

## Get one row per response

Task files hold far more rows than responses. Instructions, fixation
crosses, continue buttons and audio events all get rows of their own.
[`gorilla_trials()`](https://mcanzi.de/silverback/reference/gorilla_trials.md)
keeps only the rows with a response:

``` r

ld <- gorilla_trials(g, task = "Lexical decision")
ld
#> # A tibble: 87 × 19
#>   participant_private_id experiment_version tree_node_key repeat_key task_name  
#>   <chr>                               <int> <chr>         <chr>      <chr>      
#> 1 9100037                                 3 task-ld2k     NA         Lexical de…
#> 2 9100037                                 3 task-ld2k     NA         Lexical de…
#> 3 9100037                                 3 task-ld2k     NA         Lexical de…
#> 4 9100037                                 3 task-ld2k     NA         Lexical de…
#> 5 9100037                                 3 task-ld2k     NA         Lexical de…
#> 6 9100037                                 3 task-ld2k     NA         Lexical de…
#> # ℹ 81 more rows
#> # ℹ 14 more variables: task_version <int>, spreadsheet <chr>, trial <dbl>,
#> #   display <chr>, screen <chr>, component <chr>, object <chr>, response <chr>,
#> #   rt <dbl>, correct <lgl>, time <dttm>, spreadsheet_word <chr>,
#> #   spreadsheet_lexicality <chr>, spreadsheet_answer <chr>
```

The first columns are the same for every task, whichever builder it was
made with. The table below lists them.

| Column | Content |
|----|----|
| `participant_private_id` | Gorilla’s ID for the participant |
| `experiment_version`, `tree_node_key`, `repeat_key` | where in the experiment the response was given |
| `task_name`, `task_version` | the task and its version |
| `spreadsheet`, `trial` | the spreadsheet and trial number |
| `display`, `screen` | the display and screen (Task Builder 1 has no displays) |
| `component`, `object` | what recorded the response (zone type and zone name in Task Builder 1) |
| `response`, `rt`, `correct` | the response, the reaction time in ms and whether it was correct |
| `time` | when the response was given, in UTC |

Next come the timing columns that Gorilla recorded for the responses,
such as `onset_time` and `response_duration` in Task Builder 2 or
`reaction_onset` in Task Builder 1. Columns without values are left out.
The invented example has no timing data, so these columns are missing
below. The spreadsheet and store columns of the task follow, so the
conditions are ready to use:

``` r

ld |>
  filter(correct) |>
  summarise(rt = median(rt), .by = spreadsheet_lexicality)
#> # A tibble: 2 × 2
#>   spreadsheet_lexicality    rt
#>   <chr>                  <dbl>
#> 1 nonword                 723.
#> 2 word                    650.
```

Leave out `task` to get the responses of all tasks in one table. If you
need the rows around each response, such as the moment an audio file
started, use `all_rows = TRUE`. Every column of the export, including
the metadata left out here, remains in `g$tasks`.

## Get one row per participant for questionnaires

[`gorilla_wide()`](https://mcanzi.de/silverback/reference/gorilla_wide.md)
puts each questionnaire item in its own column:

``` r

answers <- gorilla_wide(g)
answers
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

Dropdowns, multiple choice questions and Likert scales also have a
quantised value, the position of the chosen option, which goes into a
second column ending in `_quantised`. Checkboxes give one column per
option, such as `languages_german`. Questionnaires from both builders
and in both download formats end up with the same column names.

Sometimes a participant answers an item twice. This happens after a
repeated node, or when two questions in the same questionnaire share an
object name. The first answer stays in the item’s column and later
answers go into columns ending in `__2`, `__3` and so on.

## Get one row per participant for everything else

[`gorilla_participants()`](https://mcanzi.de/silverback/reference/gorilla_participants.md)
collects what Gorilla records about each person:

``` r

people <- gorilla_participants(g)
people
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

Each row has the participant’s status, device, operating system and
browser. It also has the times of the first and last event with the
minutes in between, the group that each randomiser or branch node
assigned, and the last value of each store field. Columns that are empty
for everybody are dropped. `status = "complete"` keeps only participants
who finished.

## Put the tables together

The three tables share `participant_private_id`, so they can be joined
with
[`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html).
Here the background questionnaire and the randomiser group are added to
each response:

``` r

ld |>
  left_join(select(answers, participant_private_id, age, gender), by = "participant_private_id") |>
  left_join(select(people, participant_private_id, randomiser_ab12), by = "participant_private_id") |>
  select(participant_private_id, spreadsheet_word, rt, age, gender, randomiser_ab12)
#> # A tibble: 87 × 6
#>   participant_private_id spreadsheet_word    rt   age gender randomiser_ab12
#>   <chr>                  <chr>            <dbl> <int> <chr>  <chr>          
#> 1 9100037                mukket            628.    23 Female List A         
#> 2 9100037                venisk            733.    23 Female List A         
#> 3 9100037                mirror            840.    23 Female List A         
#> 4 9100037                drosk            1110.    23 Female List A         
#> 5 9100037                basket            470.    23 Female List A         
#> 6 9100037                pencil            650.    23 Female List A         
#> # ℹ 81 more rows
```

All three can go straight into dplyr or ggplot2.

## Before sharing the data

If you recruited through a platform such as Prolific, the public IDs are
the platform’s IDs and can identify people.
[`blind_ids()`](https://mcanzi.de/silverback/reference/blind_ids.md)
replaces them, the external session IDs and the completion codes with
codes such as `P001`, consistently across all tables:

``` r

blind_ids(g) |>
  gorilla_participants() |>
  select(participant_private_id, participant_public_id)
#> # A tibble: 6 × 2
#>   participant_private_id participant_public_id
#>   <chr>                  <chr>                
#> 1 9100037                P001                 
#> 2 9100074                P002                 
#> 3 9100111                P003                 
#> 4 9100148                P004                 
#> 5 9100185                P005                 
#> 6 9100222                P006
```

Gorilla’s private IDs stay, because they mean nothing outside Gorilla.
Free-text answers can still hold personal information such as email
addresses, so check the questionnaires before you share them.

## Save the tables as CSV files

To continue the analysis in other software, or to share the data,
[`write_gorilla()`](https://mcanzi.de/silverback/reference/write_gorilla.md)
writes the tables to a folder of CSV files:

``` r

out <- file.path(tempdir(), "tidy")
files <- write_gorilla(blind_ids(g), out)
basename(files)
#> [1] "participants.csv"        "trials.csv"             
#> [3] "questionnaires.csv"      "questionnaires_long.csv"
```

The folder has `participants.csv`, `trials.csv`, `questionnaires.csv`
with one row per participant and `questionnaires_long.csv` with one row
per answer. Missing values are empty cells and times are in UTC. With
`by_task = TRUE`, each task gets its own trials file, which keeps only
the spreadsheet columns of that task. Existing files are only replaced
with `overwrite = TRUE`.
