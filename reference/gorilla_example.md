# Path to the example exports

The package includes a small invented experiment downloaded in the
one-file-per-node format: a lexical decision task made with Task Builder
2, a rhyme judgement task made with Task Builder 1, a consent form made
with Questionnaire Builder 1 and a background questionnaire made with
Questionnaire Builder 2. One participant stopped during the lexical
decision task, and one node was never reached, so its file is empty. For
the first participant, the lexical decision task also has the recordings
of the Eye Tracking and Mouse Tracking components: a calibration, gaze
on the first three trials and the mouse moving to the continue button of
the instructions. The data were simulated and the identifiers are made
up.

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
#>  [1] "123456-3-9100037-task-ld2k-50000037-calibration-1-1.csv"  
#>  [2] "123456-3-9100037-task-ld2k-50000037-collection-1-1.csv"   
#>  [3] "123456-3-9100037-task-ld2k-50000037-collection-2-1.csv"   
#>  [4] "123456-3-9100037-task-ld2k-50000037-collection-3-1.csv"   
#>  [5] "123456-3-9100037-task-ld2k-50000037-mousetracking-1-1.csv"
#>  [6] "data_exp_123456-v3_questionnaire-bg9q.csv"                
#>  [7] "data_exp_123456-v3_questionnaire-cn4x.csv"                
#>  [8] "data_exp_123456-v3_questionnaire-zz1e.csv"                
#>  [9] "data_exp_123456-v3_task-ld2k.csv"                         
#> [10] "data_exp_123456-v3_task-rh7p.csv"                         
```
