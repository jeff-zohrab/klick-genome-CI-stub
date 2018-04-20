param(
  $site_ip,
  $selenium_hub_url,

  # If nunit_filter is '' or null, run all tests.
  $nunit_filter,

  $report_to_testrail = "false",
  $branch_name
)

echo ">>> FAKE RUN OF SELENIUM"
echo "run_test.ps1 called with args:"
echo " * site_ip: ${site_ip}"
echo " * selenium_hub_url: ${selenium_hub_url}"
echo " * nunit_filter: ${nunit_filter}"
echo " * report_to_testrail: ${report_to_testrail}"
echo " * branch_name: ${branch_name}"

$path = "$PSScriptRoot\simulate_selenium_failure.txt"
if (Test-Path $path) {
  throw "Simulate error! (found file at ${path})"
}
else {
  echo "Simulate success!"
}