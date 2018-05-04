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

`simulate_failure/simulate_failure_for_current_branch.rb` is included
in the `Rakefile` to simulate errors.  You can simulate errors for
branches:

The `DEFAULT.rb` in `simulate_failure/` is shared by all branches, and
is executed first.  If you edit this in several branches, you may get
merge conflicts.  Use per-branch simulations where possible.

In `simulate_failure/`, create `{branch_name}.rb`, where
`{branch_name}` is the current branch name.  See `demonstration.rb`
for an example.

