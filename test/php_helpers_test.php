<?php
// Cross-language cfg test: PHP writes, shell reads back.
require __DIR__ . '/../src/usr/local/emhttp/plugins/komari-agent/include/Helpers.php';

function check($cond, $msg) {
  if (!$cond) { fwrite(STDERR, "FAIL: $msg\n"); exit(1); }
}

$tmp = tempnam(sys_get_temp_dir(), 'kmcfg');
km_cfg_save(['ENDPOINT' => 'https://p.example.com', 'TOKEN' => 'abc"123'], $tmp);

$loaded = km_cfg_load($tmp);
check($loaded['ENDPOINT'] === 'https://p.example.com', 'PHP load ENDPOINT');

$common = __DIR__ . '/../src/usr/local/emhttp/plugins/komari-agent/scripts/common.sh';
$shellVal = trim(shell_exec('. ' . escapeshellarg($common) . ' && km_cfg_get ' . escapeshellarg($tmp) . ' ENDPOINT'));
check($shellVal === 'https://p.example.com', 'shell reads PHP-written ENDPOINT');

unlink($tmp);
echo "OK\n";
