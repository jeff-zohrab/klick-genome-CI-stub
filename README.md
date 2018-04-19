# Stub project

A stub repo that responds to the same build and CI commands as klick-genome.

To create the stub:

* checkout this repo as a sibling of a full klick-genome checkout.
* call `setup.rb`
* commit any changes and push


## Important subdirs that mirror those in klick-genome

* `Jenkins`
* `QA\Jenkins`
* `Scripts`

## Simulating failure

In `simulate_failure/`, create a directory matching your branch name.
Push that branch.  The pipeline should fail for that branch at that
step.