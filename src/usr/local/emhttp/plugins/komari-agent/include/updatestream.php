<?php
// SSE endpoint for the UI "Check Update": runs fetch.sh (force) and, if the
// agent is enabled, restarts it — streaming each output line to the browser so
// the popup updates live (like Unraid's plugin-install dialog). Ends with a
// named "done" event.
require_once __DIR__ . '/Helpers.php';
@ini_set('zlib.output_compression', '0');
@ini_set('output_buffering', '0');
@ini_set('implicit_flush', '1');
while (ob_get_level() > 0) { ob_end_flush(); }
set_time_limit(0);
ignore_user_abort(true);          // finish the update even if the popup is closed

header('Content-Type: text/event-stream');
header('Cache-Control: no-cache');
header('Connection: keep-alive');
header('X-Accel-Buffering: no');  // tell nginx not to buffer this response

function km_emit($data) {
  $data = rtrim($data, "\r\n");
  echo 'data: ' . str_replace("\n", "\ndata: ", $data) . "\n\n";
  @flush();
}

// run a command, streaming combined stdout/stderr line by line; returns exit code
function km_stream($cmd) {
  $p = popen($cmd . ' 2>&1', 'r');
  if (!is_resource($p)) { km_emit('(cannot run command)'); return 1; }
  while (($line = fgets($p)) !== false) { km_emit($line); }
  return pclose($p);
}

$cfg   = km_cfg_load();
$ver   = $cfg['VERSION'] ?? 'latest';
$ghp   = $cfg['GHPROXY'] ?? '';
$fetch = km_scripts_dir() . '/fetch.sh';
$rc    = km_scripts_dir() . '/rc.komari-agent';

km_stream(escapeshellarg($fetch) . ' ' . escapeshellarg($ver) . ' ' . escapeshellarg($ghp) . ' force');

if (($cfg['ENABLED'] ?? 'no') === 'yes') {
  km_emit('[rc] restarting agent');
  km_stream(escapeshellarg($rc) . ' restart');
}

echo "event: done\ndata: done\n\n";
@flush();
