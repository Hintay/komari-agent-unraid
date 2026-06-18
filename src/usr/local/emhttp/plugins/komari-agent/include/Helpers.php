<?php
// Read/write the komari-agent cfg in the KEY="value" format shared with shell scripts.

function km_cfg_path() {
  return "/boot/config/plugins/komari-agent/komari-agent.cfg";
}

function km_cfg_load($file = null) {
  $file = $file ?: km_cfg_path();
  $cfg = [];
  if (is_file($file)) {
    foreach (file($file, FILE_IGNORE_NEW_LINES) as $line) {
      if (preg_match('/^([A-Z_]+)="(.*)"$/', $line, $m)) {
        $cfg[$m[1]] = $m[2];
      }
    }
  }
  return $cfg;
}

function km_cfg_save($cfg, $file = null) {
  $file = $file ?: km_cfg_path();
  $out = "";
  foreach ($cfg as $k => $v) {
    // strip embedded double-quotes to keep the line shell-source safe
    $v = str_replace('"', '', (string)$v);
    $out .= sprintf('%s="%s"' . "\n", $k, $v);
  }
  file_put_contents($file, $out);
}

function km_scripts_dir() {
  return "/usr/local/emhttp/plugins/komari-agent/scripts";
}

/* ---- i18n: follow Unraid's active locale, English source string as the key ----
   Same idea as Unraid's _() (read $_SESSION['locale'], key on the English text),
   but the per-locale files ship inside this plugin so it works without a
   matching language pack. Files: ../languages/<locale>.txt, format English=译文. */

function km_locale() {
  $loc = $_SESSION['locale'] ?? '';
  return preg_replace('/[^A-Za-z_]/', '', (string)$loc);   // sanitize -> safe filename
}

function km_lang() {
  static $map = null;
  if ($map !== null) return $map;
  $map = [];
  $loc = km_locale();
  if ($loc === '' || $loc === 'en_US') return $map;        // English is the source
  $file = __DIR__ . '/../languages/' . $loc . '.txt';
  if (!is_file($file)) return $map;
  foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    if ($line === '' || $line[0] === '#') continue;         // comments / blanks
    $pos = strpos($line, '=');
    if ($pos === false) continue;
    $k = trim(substr($line, 0, $pos));
    $v = trim(substr($line, $pos + 1));
    if (strlen($v) >= 2 && $v[0] === '"' && substr($v, -1) === '"') $v = substr($v, 1, -1);
    if ($k !== '') $map[$k] = $v;
  }
  return $map;
}

// translate
function km_t($text) {
  $m = km_lang();
  return $m[$text] ?? $text;
}

// translate + HTML-escape (for page output)
function km_ht($text) {
  return htmlspecialchars(km_t($text));
}
