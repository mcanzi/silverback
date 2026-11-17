# silverback

silverback reads the data downloaded from the [Gorilla Experiment
Builder](https://gorilla.sc/) and turns it into tidy tibbles. A Gorilla
export has one row per event, dozens of metadata columns, marker rows,
an `END OF FILE` line and a different layout for each task and
questionnaire builder. silverback sorts this into three tibbles:
responses in tasks, answers to questionnaires and one row per
participant.

It reads

- Task Builder 1 and Task Builder 2 data,
- Questionnaire Builder 1 and Questionnaire Builder 2 data, in long and
  short format,
- downloads with one file per node and combined downloads,
- several versions of an experiment at once,
- CSV and Excel downloads,
- folders, single files and ZIP archives as downloaded, also after CSV
  files were saved again with semicolons or tabs,
- recordings of the Eye Tracking (Webgazer) and Mouse Tracking
  components of Task Builder 2.

Files from nodes that no participant reached are skipped.

## Installation

silverback is not on CRAN yet. Install it from R-universe:

``` r

install.packages("silverback", repos = c("https://mcanzi.r-universe.dev", "https://cloud.r-project.org"))
```

## Example

The package includes a small invented experiment with a lexical decision
task (Task Builder 2), a rhyme judgement task (Task Builder 1), a
consent form (Questionnaire Builder 1) and a background questionnaire
(Questionnaire Builder 2).

``` r

library(silverback)

g <- read_gorilla(gorilla_example())
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

[`gorilla_trials()`](https://mcanzi.de/silverback/reference/gorilla_trials.md)
keeps one row per response and gives both task builders the same
columns, followed by the timing, spreadsheet and store columns of the
task:

``` r

gorilla_trials(g, task = "Lexical decision")
```

[`gorilla_wide()`](https://mcanzi.de/silverback/reference/gorilla_wide.md)
gives one row per participant and one column per questionnaire item.
Items with a quantised value, such as Likert scales and dropdowns, get a
second column ending in `_quantised`:

``` r

gorilla_wide(g)
```

[`gorilla_participants()`](https://mcanzi.de/silverback/reference/gorilla_participants.md)
lists each participant’s status, device, start and end time, randomiser
and branch outcomes and the last value of each store field:

``` r

gorilla_participants(g, status = "complete")
```

[`summary()`](https://rdrr.io/r/base/summary.html) describes each task
and questionnaire in one row, and
[`gorilla_checks()`](https://mcanzi.de/silverback/reference/gorilla_checks.md)
lists participants who may need a closer look: incomplete participants,
people who took part twice, missing tasks, very fast or identical
responses, unusual devices and randomiser groups of unequal size.

``` r

summary(g)
gorilla_checks(g)
```

To read your own data, give
[`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md)
the folder or ZIP file you downloaded from the Data tab:

``` r

g <- read_gorilla("data_exp_123456-v3.zip")
```

Recordings of the Eye Tracking (Webgazer) and Mouse Tracking components
of Task Builder 2 are saved in separate files, one per trial.
[`read_eyetracking()`](https://mcanzi.de/silverback/reference/read_eyetracking.md)
and
[`read_mousetracking()`](https://mcanzi.de/silverback/reference/read_mousetracking.md)
read them, assign each sample to the zone of the screen it falls in, and
take the task and screen names from the main export:

``` r

eye <- read_eyetracking("data", x = g)
eye$gaze         # one row per gaze sample
eye$calibration  # accuracy of each calibration point
mouse <- read_mousetracking("data", x = g)
```

If the public IDs come from a recruitment platform such as Prolific,
[`blind_ids()`](https://mcanzi.de/silverback/reference/blind_ids.md)
replaces them with codes before you share the data.

[`write_gorilla()`](https://mcanzi.de/silverback/reference/write_gorilla.md)
saves the tidy tables as CSV files, for analysis in other software:

``` r

write_gorilla(blind_ids(g), "tidy")
```

## Check your data

silverback has been tested on real exports from many different
experiments, made with both task builders and both questionnaire
builders and downloaded per node or combined, as CSV or Excel files.
Gorilla changes its exports from time to time, however, and a new format
or an unusual experiment may give results that are not what you expect.
Before you analyse or publish data read with silverback, compare the
tables with your raw files, for example the number of participants and
of responses in each task.
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`gorilla_checks()`](https://mcanzi.de/silverback/reference/gorilla_checks.md)
help with this.

If a file is read wrongly or not at all, please [open an
issue](https://github.com/mcanzi/silverback/issues). A small example
file helps a lot, but remove personal data such as Prolific IDs or email
addresses before you share it.

## Disclaimer

silverback is free software under the [MIT
licence](https://opensource.org/license/mit). It comes without warranty
of any kind, and its authors are not liable for any claim or damage
arising from its use; see the licence for the full terms.

Gorilla is made by Cauldron Science. silverback is not affiliated with
or endorsed by Cauldron Science. It reads the files that Gorilla exports
and does not connect to Gorilla.
