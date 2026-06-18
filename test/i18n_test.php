<?php
// Translation completeness check: every English UI string the page/JS uses must
// have a non-empty translation in each shipped language file.
require_once __DIR__ . '/../src/usr/local/emhttp/plugins/komari-agent/include/Helpers.php';

$base = __DIR__ . '/../src/usr/local/emhttp/plugins/komari-agent';
$fail = 0;
function err($m) { global $fail; $fail++; fwrite(STDERR, "FAIL: $m\n"); }

// 1. functional: the helper translates via the active locale, English as the key
$_SESSION['locale'] = 'zh_CN';
if (km_t('Enabled') !== '启用') err("km_t('Enabled') zh_CN expected 启用, got '" . km_t('Enabled') . "'");
if (km_t('No Such Key Xyz') !== 'No Such Key Xyz') err('missing key should fall back to English');

// 2. required keys = every English literal that reaches a translator:
//    km_t()/km_ht() in the page, kt() in the JS, and the km_set_status() literal.
$page = file_get_contents("$base/komari-agent.page");
$js   = file_get_contents("$base/komari-agent.js");
preg_match_all("/km_h?t\\('([^']*)'\\)/", $page, $mp);
preg_match_all("/\\bkt\\('([^']*)'\\)/", $js, $mj);
preg_match_all("/km_set_status\\('([^']*)'\\)/", $js, $ms);
$keys = array_values(array_unique(array_merge($mp[1], $mj[1], $ms[1])));

// 3. each language file must define every key, with no dupes and no empty values
foreach (['zh_CN', 'zh_TW', 'ja_JP'] as $loc) {
  $file = "$base/languages/$loc.txt";
  if (!is_file($file)) { err("missing language file $loc.txt"); continue; }
  $map = [];
  foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    if ($line === '' || $line[0] === '#') continue;
    $pos = strpos($line, '=');
    if ($pos === false) continue;
    $k = trim(substr($line, 0, $pos));
    $v = trim(substr($line, $pos + 1));
    if (isset($map[$k])) err("$loc: duplicate key '$k'");
    $map[$k] = $v;
  }
  foreach ($keys as $k) {
    if (!isset($map[$k]))      err("$loc: missing translation for '$k'");
    elseif ($map[$k] === '')   err("$loc: empty translation for '$k'");
  }
}

if ($fail) { fwrite(STDERR, "$fail failure(s)\n"); exit(1); }
echo 'OK (' . count($keys) . " keys x 3 locales)\n";
