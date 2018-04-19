$path = "$PSScriptRoot\simulate_selenium_failure.txt"
if (Test-Path $path) {
  throw "Simulate error! (found file at ${path})"
}
else {
  echo "Simulate success!"
}