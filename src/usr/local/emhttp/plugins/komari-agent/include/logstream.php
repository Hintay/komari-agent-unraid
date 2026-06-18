<?php
// SSE endpoint: live-streams the komari-agent log (tail -F) to the browser.
// Each client holds one php-fpm worker until it disconnects or maxDuration is
// reached; EventSource then reconnects automatically.
@ini_set('zlib.output_compression', '0');
@ini_set('output_buffering', '0');
@ini_set('implicit_flush', '1');
while (ob_get_level() > 0) { ob_end_flush(); }
set_time_limit(0);
ignore_user_abort(true);   // we clean up the tail process ourselves on abort

header('Content-Type: text/event-stream');
header('Cache-Control: no-cache');
header('Connection: keep-alive');
header('X-Accel-Buffering: no');   // tell nginx not to buffer this response

$log = '/var/log/komari-agent.log';

function km_emit($data) {
  // a single agent line may contain embedded newlines; map each to its own SSE data: field
  $data = rtrim($data, "\r\n");
  echo 'data: ' . str_replace("\n", "\ndata: ", $data) . "\n\n";
  @flush();
}

if (!is_file($log)) {
  km_emit('(no log yet)');
  exit;
}

$descriptors = [1 => ['pipe', 'w'], 2 => ['file', '/dev/null', 'a']];
$proc = proc_open('tail -n 200 -F ' . escapeshellarg($log), $descriptors, $pipes);
if (!is_resource($proc)) { km_emit('(cannot open log)'); exit; }
$out = $pipes[1];
stream_set_blocking($out, false);

$start = time();
$maxDuration = 1800; // 30 min cap; client auto-reconnects

while (true) {
  if (connection_aborted()) break;
  if ((time() - $start) > $maxDuration) break;

  $line = fgets($out);
  if ($line === false) {
    if (feof($out)) break;            // tail exited
    echo ": ping\n\n"; @flush();      // heartbeat doubles as disconnect detection
    if (connection_aborted()) break;
    usleep(500000);                   // 0.5s idle wait
    continue;
  }
  km_emit($line);
}

fclose($out);
proc_terminate($proc);   // kill the tail child so no process leaks
proc_close($proc);
