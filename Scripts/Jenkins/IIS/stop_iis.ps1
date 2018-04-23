# Stop iis if it's running.
echo "Stop IIS if it's running"
Try {
  iisreset /stop
}
Catch {
  # Ignore ... IIS may not be running.
}
echo "Done stop IIS"
