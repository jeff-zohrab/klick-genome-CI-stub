param(
  $site_ip,
  $selenium_hub_url,

  # If nunit_filter is '' or null, run all tests.
  $nunit_filter,

  $report_to_testrail = "false",
  $branch_name
)

$selargs = "branch_name: ${branch_name}; nunit_filter: ${nunit_filter}; report_to_testrail: ${report_to_testrail}"

echo ">>>>>> FAKE RUN OF SELENIUM"
echo "run_test.ps1 called with args:"
echo " ${selargs}"

Add-Content -Path "c:\www\report_runs.txt" -Value "`r`n${selargs}"

$path = "$PSScriptRoot\simulate_selenium_failure.txt"
if (Test-Path $path) {
  throw "Simulate error! (found file at ${path})"
}
else {
  echo "Simulate success!"
}