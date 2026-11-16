# Path to the example exports

The package includes a small invented experiment downloaded in the
one-file-per-node format: a lexical decision task made with Task Builder
2, a rhyme judgement task made with Task Builder 1, a consent form made
with Questionnaire Builder 1 and a background questionnaire made with
Questionnaire Builder 2. One participant stopped during the lexical
decision task, and one node was never reached, so its file is empty. The
data were simulated and the identifiers are made up.

## Usage

``` r
gorilla_example(file = NULL)
```

## Arguments

- file:

  Name of one file. If `NULL`, the path to the folder.

## Value

A path.

## Examples

``` r
gorilla_example()
#> [1] "/home/runner/work/_temp/Library/silverback/extdata/example"
list.files(gorilla_example())
#> [1] "data_exp_123456-v3_questionnaire-bg9q.csv"
#> [2] "data_exp_123456-v3_questionnaire-cn4x.csv"
#> [3] "data_exp_123456-v3_questionnaire-zz1e.csv"
#> [4] "data_exp_123456-v3_task-ld2k.csv"         
#> [5] "data_exp_123456-v3_task-rh7p.csv"         
```
