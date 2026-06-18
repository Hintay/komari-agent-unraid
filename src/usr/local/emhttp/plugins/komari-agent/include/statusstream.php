<?php
// SSE endpoint: pushes agent status changes to the browser.
// Checks the PID file every 2 seconds; only emits an event when the state
// actually changes (or on first connect), so idle connections are cheap.
@ini_set('zlib.output_compression', '0');
@ini_set('output_buffering', '0');
@ini_set('implicit_flush', '1');
while (ob_get_level() > 0) { ob_end_flush(); }
set_time_limit(0);
ignore_user_abort(false);

header('Content-Type: text/event-stream');
header('Cache-Control: no-cache');
header('Connection: keep-alive');
header('X-Accel-Buffering: no');

$pidFile = '/var/run/komari-agent.pid';
$last    = null;
$start   = time();
$maxDuration = 1800; // 30 min cap; EventSource auto-reconnects

while (!connection_aborted()) {
  if ((time() - $start) > $maxDuration) break;

  $running = false;
  if (is_file($pidFile)) {
    $pid = trim(@file_get_contents($pidFile));
    if ($pid !== '' && $pid !== false && is_dir("/proc/$pid")) {
      $running = true;
    }
  }

  $state = $running ? "running ($pid)" : 'stopped';
  if ($state !== $last) {
    echo "data: $state\n\n";
    @flush();
    $last = $state;
  } else {
    echo ": ping\n\n";
    @flush();
  }

  if (connection_aborted()) break;
  sleep(2);
}
