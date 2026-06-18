<?php
// AJAX action endpoint for the Komari Agent plugin.
// POST: action=save  (+ form fields)
require_once __DIR__ . '/Helpers.php';
header('Content-Type: application/json');

$rc = km_scripts_dir() . '/rc.komari-agent';

function out($ok, $msg) { echo json_encode(['ok' => $ok, 'msg' => $msg]); exit; }

$action = $_POST['action'] ?? '';

switch ($action) {
  case 'save':
    $keys = ['ENABLED','ENDPOINT','CONN_MODE','TOKEN','AD_KEY','DISABLE_WEB_SSH','AUTO_UPDATE',
             'INTERVAL','IGNORE_UNSAFE_CERT','EXTRA_ARGS','VERSION','GHPROXY'];
    $boolKeys = ['ENABLED','DISABLE_WEB_SSH','IGNORE_UNSAFE_CERT','AUTO_UPDATE'];
    $cfg = km_cfg_load();
    foreach ($keys as $k) {
      if (in_array($k, $boolKeys, true)) continue;
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

  default:
    out(false, 'unknown action');
}
