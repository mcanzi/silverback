# silverback: Tidy 'Gorilla' Experiment Builder Exports

Reads the data files downloaded from the 'Gorilla' Experiment Builder
<https://gorilla.sc/> and turns them into tidy tibbles. Files from Task
Builder 1 and 2 and from Questionnaire Builder 1 and 2 can be read
together, whether they were downloaded as one file per node or as
combined files, and from several versions of an experiment. Task data
are reduced to one row per response with the same columns for both task
builders. Questionnaire answers are returned with one row per
participant, and participant information such as status, device,
randomiser outcomes and stored values is collected in one table.
Recordings of the eye tracking and mouse tracking components are read
with each sample assigned to a zone of the screen. A summary and a set
of checks point out incomplete or repeated participation and unusual
response patterns before the analysis. The tables can be saved as CSV
files for use in other software.

## Details

Gorilla is a product of Cauldron Science. The package is not affiliated
with or endorsed by Cauldron Science. It reads the files that 'Gorilla'
exports and does not connect to 'Gorilla'.

## See also

Useful links:

- <https://github.com/mcanzi/silverback>

- <https://mcanzi.de/silverback/>

- Report bugs at <https://github.com/mcanzi/silverback/issues>

## Author

**Maintainer**: Massimiliano Canzi <massimiliano.canzi@uni-konstanz.de>
([ORCID](https://orcid.org/0000-0001-6124-0321)) \[copyright holder\]
