# Changelog

## silverback 0.0.0.9000

- [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md)
  reads exports from Task Builder 1 and 2 and Questionnaire Builder 1
  and 2, in long and short format, downloaded as one file per node or as
  combined files, from folders, single files or ZIP archives. Codes such
  as `007` and keys such as `T` stay text.
- [`gorilla_trials()`](https://mcanzi.de/silverback/reference/gorilla_trials.md)
  returns one row per response with the same columns for both task
  builders, including the repeat key, the task version and the timing
  columns of the export.
- [`gorilla_wide()`](https://mcanzi.de/silverback/reference/gorilla_wide.md)
  returns questionnaire answers with one row per participant.
- [`gorilla_participants()`](https://mcanzi.de/silverback/reference/gorilla_participants.md)
  collects status, device, timing, randomiser, branch and checkpoint
  outcomes and store values per participant.
- [`summary()`](https://rdrr.io/r/base/summary.html) describes each task
  and questionnaire, and
  [`gorilla_checks()`](https://mcanzi.de/silverback/reference/gorilla_checks.md)
  lists incomplete participants, repeated participation, missing tasks,
  fast or identical responses, unusual devices and unbalanced
  randomisers.
- [`blind_ids()`](https://mcanzi.de/silverback/reference/blind_ids.md)
  replaces public participant identifiers.
- [`write_gorilla()`](https://mcanzi.de/silverback/reference/write_gorilla.md)
  writes the tidy tables to CSV files.
- [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md)
  no longer warns about parsing issues when the `END OF FILE` row has no
  trailing commas, as in recent exports. Other rows with the wrong
  number of columns give one warning that names the file.
