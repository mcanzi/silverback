# Read Gorilla exports

Reads the CSV or Excel files downloaded from the Data tab of the
'Gorilla' Experiment Builder and sorts them into tasks, questionnaires
and participants. Both kinds of download are read: one file per node of
the experiment tree (`data_exp_12345-v6_task-ab12.csv`) and the combined
files (`data_exp_12345-v6_tasks.csv`,
`data_exp_12345-v6_questionnaires.csv`).

## Usage

``` r
read_gorilla(path, quiet = FALSE)
```

## Arguments

- path:

  Paths to folders, CSV or Excel files, or ZIP archives. Folders and ZIP
  archives are searched recursively for CSV and Excel files whose names
  start with `data_exp_`, the names 'Gorilla' gives its downloads. Files
  named directly are read whatever their name.

- quiet:

  If `TRUE`, no message about skipped files is shown.

## Value

An object of class `gorilla_data`: a list with

- tasks:

  All rows of all task files, one row per event, with cleaned column
  names, plus `builder` (the task builder that made the file) and `file`
  (the file the row comes from). See
  [`gorilla_trials()`](https://mcanzi.de/silverback/reference/gorilla_trials.md)
  for one row per response.

- questionnaires:

  All questionnaire answers in long format, one row per participant and
  item, with columns `item`, `response`, `quantised` and `file`. See
  [`gorilla_wide()`](https://mcanzi.de/silverback/reference/gorilla_wide.md)
  for one row per participant.

- participants:

  One row per participant. See
  [`gorilla_participants()`](https://mcanzi.de/silverback/reference/gorilla_participants.md).

- files:

  One row per file read, with the experiment, version, node, builder,
  task and number of rows.

## Details

Excel files (`.xlsx`) are read with every cell as text, so they give the
same tables as the CSV download. Some Excel downloads store numbers as
numbers, though, and a code such as `007` saved that way has already
lost its leading zeros in the file. Download CSV files if such codes
matter.

Files from Task Builder 1 and 2 and from Questionnaire Builder 1 and 2
can be mixed, and so can files from several versions of the experiment.
The `END OF FILE` row at the end of each file is removed, and files from
nodes that no participant reached, which hold no data, are skipped.
Files that were opened in a spreadsheet program and saved again with
semicolons or tabs as separators are read too. If the files include both
kinds of download, or the same file as CSV and as Excel, a warning says
so, because the same rows would then be read twice. Lines with the wrong
number of columns, as in a file that was cut off or edited by hand, also
give a warning.

Column names are converted to snake case: `Participant Private ID`
becomes `participant_private_id`, `Spreadsheet: Speaker` becomes
`spreadsheet_speaker` and `Store: Alter` becomes `store_alter`.
Spreadsheet columns from Task Builder 1, which have no prefix in the
export, get the same `spreadsheet_` prefix.

A column becomes numeric only if every value in it is a number without
leading zeros, so codes such as `007` and response keys such as `T` and
`F` stay text. Identifiers and responses always stay text.

## See also

[`gorilla_trials()`](https://mcanzi.de/silverback/reference/gorilla_trials.md),
[`gorilla_wide()`](https://mcanzi.de/silverback/reference/gorilla_wide.md),
[`gorilla_participants()`](https://mcanzi.de/silverback/reference/gorilla_participants.md)

## Examples

``` r
path <- gorilla_example()
g <- read_gorilla(path)
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
