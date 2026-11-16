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
- [`read_gorilla()`](https://mcanzi.de/silverback/reference/read_gorilla.md)
  reads files saved with tabs as separators, also when a question text
  in the header contains commas or line breaks, and no longer treats the
  `UTC Date` and `Local Date` columns of older exports as spreadsheet
  columns.
- Objects of Questionnaire Builder 2 that share a name within a
  questionnaire, such as several objects left as `Rating Scale`, are now
  kept apart by their object ID instead of being treated as repeated
  answers.
- [`read_eyetracking()`](https://mcanzi.de/silverback/reference/read_eyetracking.md)
  and
  [`read_mousetracking()`](https://mcanzi.de/silverback/reference/read_mousetracking.md)
  read the recordings of the Eye Tracking (Webgazer) and Mouse Tracking
  components of Task Builder 2: gaze and mouse samples assigned to
  screen zones, the zones themselves, and the accuracy and outcome of
  each calibration attempt.
- [`gorilla_trials()`](https://mcanzi.de/silverback/reference/gorilla_trials.md)
  gives a message when a component, such as a Click Response without
  response values, recorded empty responses, and
  [`gorilla_checks()`](https://mcanzi.de/silverback/reference/gorilla_checks.md)
  then uses the clicked object for the `same_response` check. The
  `response` column itself is not changed.
