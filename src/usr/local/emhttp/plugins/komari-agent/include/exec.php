<?php
// AJAX action endpoint for the Komari Agent plugin.
// POST: action=save|start|stop|restart|update|status|log  (+ form fields for save)
require_once __DIR__ . '/Helpers.php';
header('Content-Type: application/json');

$rc    = km_scripts_dir() . '/rc.komari-agent';
$fetch = km_scripts_dir() . '/fetch.sh';

function out($ok, $msg) { echo json_encode(['ok' => $ok, 'msg' => $msg]); exit; }

$action = $_POST['action'] ?? $_GET['action'] ?? '';

switch ($action) {
  case 'save':
    $keys = ['ENABLED','ENDPOINT','CONN_MODE','TOKEN','AD_KEY','DISABLE_WEB_SSH','AUTO_UPDATE',
             'INTERVAL','IGNORE_UNSAFE_CERT','EXTRA_ARGS','VERSION','GHPROXY'];
    $boolKeys = ['ENABLED','DISABLE_WEB_SSH','IGNORE_UNSAFE_CERT','AUTO_UPDATE'];
    $cfg = km_cfg_load();
    foreach ($keys as $k) {
      if (in_array($k, $boolKeys, true)) continue;   // bool keys normalized below
      if (isset($_POST[$k])) $cfg[$k] = trim($_POST[$k]);
    }
    foreach ($boolKeys as $b) {
      $cfg[$b] = (isset($_POST[$b]) && in_array($_POST[$b], ['yes','on','1'], true)) ? 'yes' : 'no';
    }
    km_cfg_save($cfg);
    if ($cfg['ENABLED'] === 'yes') shell_exec(escapeshellarg($rc).' restart 2>&1');
    else                          shell_exec(escapeshellarg($rc).' stop 2>&1');
    out(true, 'saved');
    break;

  case 'start':
    $cfg = km_cfg_load(); $cfg['ENABLED'] = 'yes'; km_cfg_save($cfg);
    out(true, shell_exec(escapeshellarg($rc).' start 2>&1'));
    break;

  case 'stop':
    $cfg = km_cfg_load(); $cfg['ENABLED'] = 'no'; km_cfg_save($cfg);
    out(true, shell_exec(escapeshellarg($rc).' stop 2>&1'));
    break;

  case 'restart':
    out(true, shell_exec(escapeshellarg($rc).' restart 2>&1'));
    break;

  case 'update':
    $cfg = km_cfg_load();
    $ver = escapeshellarg($cfg['VERSION'] ?? 'latest');
    $ghp = escapeshellarg($cfg['GHPROXY'] ?? '');
    $res = shell_exec(escapeshellarg($fetch).' '.$ver.' '.$ghp.' force 2>&1');
    if (($cfg['ENABLED'] ?? 'no') === 'yes') shell_exec(escapeshellarg($rc).' restart 2>&1');
    out(true, $res);
    break;

  case 'status':
    $s = shell_exec(escapeshellarg($rc).' status 2>&1');
    out(true, trim($s));
    break;

  case 'log':
    $log = '/var/log/komari-agent.log';
    out(true, is_file($log) ? shell_exec('/usr/bin/tail -n 200 '.escapeshellarg($log)) : '(no log yet)');
    break;

  default:
    out(false, 'unknown action');
}
