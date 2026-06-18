// Komari Agent plugin UI logic. External file so the .page Markdown renderer
// never mangles it. Uses Unraid's native jquery.switchbutton (loaded by the
// page). The advanced view fly in/out is done with jQuery's built-in
// toggle('slow'), exactly like Unraid's VM Manager (VMSettings.page toggles its
// whole .advanced block the same way).

const KM_EXEC = "/plugins/komari-agent/include/exec.php";
const KM_STREAM = "/plugins/komari-agent/include/logstream.php";
const KM_UPDATE_STREAM = "/plugins/komari-agent/include/updatestream.php";
const KM_STATUS_STREAM = "/plugins/komari-agent/include/statusstream.php";
var km_es = null;   // log viewer stream
var km_ues = null;  // update popup stream
var km_ss = null;   // status stream

// translate a UI string via the map the page injected (English key, fallback to key)
function kt(s){ return (window.KM_I18N && KM_I18N[s] != null) ? KM_I18N[s] : s; }

function km_set_status(txt){
  var running = /running/i.test(txt);
  var disp = running ? kt('Running') : (/stop/i.test(txt) ? kt('Stopped') : kt(txt));
  var el = document.getElementById('km_status');
  if(el){ el.textContent = disp; el.className = running ? 'km-run' : 'km-stop'; }
  // Start/Stop track the running state
  $('#km_btn_start').prop('disabled', running);
  $('#km_btn_stop').prop('disabled', !running);
}
function km_status_connect(){
  if(km_ss) return;
  km_ss = new EventSource(KM_STATUS_STREAM);
  km_ss.onmessage = function(e){ km_set_status(e.data); };
}

// lightweight feedback dialog — Unraid bundles SweetAlert as the global `swal`
function km_notify(title, msg, type){
  if(typeof swal === 'function'){ swal({ title: title, text: msg, type: type || 'info' }); }
  else { alert(title + "\n\n" + msg); }
}

function km_post(action){
  // read fields explicitly (switchButton wraps the checkboxes)
  var data = {action: action};
  if(action === 'save'){
    // when enabled, the agent needs an endpoint and a token / discovery key
    if($('[name="ENABLED"]').is(':checked')){
      var ep = ($('[name="ENDPOINT"]').val() || '').trim();
      var discovery = $('[name="CONN_MODE"]').val() === 'discovery';
      var key = ($(discovery ? '[name="AD_KEY"]' : '[name="TOKEN"]').val() || '').trim();
      if(!ep){ km_notify(kt('Cannot save'), kt('Panel endpoint is required when enabled.'), 'error'); return; }
      if(!key){
        var need = discovery ? kt('Auto-discovery key is required when enabled.') : kt('Token is required when enabled.');
        km_notify(kt('Cannot save'), need, 'error'); return;
      }
    }
    ['ENDPOINT','CONN_MODE','TOKEN','AD_KEY','INTERVAL','EXTRA_ARGS','VERSION','GHPROXY'].forEach(function(k){
      data[k] = $('[name="'+k+'"]').val();
    });
    ['ENABLED','DISABLE_WEB_SSH','IGNORE_UNSAFE_CERT','AUTO_UPDATE'].forEach(function(k){
      data[k] = $('[name="'+k+'"]').is(':checked') ? 'yes' : 'no';
    });
  }
  $.post(KM_EXEC, data).done(function(){
    if(action === 'save' && typeof swal === 'function'){
      swal({ title: kt('Saved'), type: 'success', timer: 1200, showConfirmButton: false });
    }
    km_status_connect();
  }).fail(function(){ km_notify(kt('Error'), kt('Action failed. Check your connection.'), 'error'); });
}

// Check Update: live-streaming popup like Unraid's plugin-install dialog
function km_update(){
  swal({
    title: kt('Check Update') + " <i id='km_upspin' class='fa fa-refresh fa-spin'></i>",
    text: "<pre id='km_swaltext'></pre>",
    html: true, animation: 'none',
    showConfirmButton: true, confirmButtonText: kt('Close')
  }, function(){ if(km_ues){ km_ues.close(); km_ues = null; } km_status_connect(); });

  var pre = document.getElementById('km_swaltext');
  if(pre){ pre.textContent = ''; }
  if(km_ues){ km_ues.close(); }
  km_ues = new EventSource(KM_UPDATE_STREAM);
  km_ues.onmessage = function(e){
    if(!pre) return;
    pre.textContent += e.data + "\n";
    pre.scrollTop = pre.scrollHeight;
  };
  km_ues.addEventListener('done', function(){
    km_ues.close(); km_ues = null;
    $('#km_upspin').removeClass('fa-refresh fa-spin').addClass('fa-check');
    km_status_connect();
  });
  km_ues.onerror = function(){ if(km_ues){ km_ues.close(); km_ues = null; } $('#km_upspin').removeClass('fa-refresh fa-spin'); };
}

function km_log(){
  var box = document.getElementById('km_logbox');
  if(km_es){ km_es.close(); km_es = null; $('#km_logbox').hide(); $('#km_btn_log').val(kt('View Log')); return; }
  $('#km_logbox').show();
  $('#km_btn_log').val(kt('Hide Log'));
  km_es = new EventSource(KM_STREAM);
  km_es.onopen = function(){ box.textContent = ''; };
  km_es.onmessage = function(e){
    var atBottom = box.scrollTop + box.clientHeight >= box.scrollHeight - 4;
    box.textContent += e.data + "\n";
    if(atBottom){ box.scrollTop = box.scrollHeight; }
  };
}

// move the status badge into the Unraid page title bar (top-right), like VM Manager
function km_place_status(){
  var bar = document.getElementById('km_statusbar');
  var title = document.querySelector('.title');
  if(title && bar){ title.appendChild(bar); }
}

// show only the field that matches the selected connection mode (instant, no animation)
function km_mode(){
  var discovery = $('[name="CONN_MODE"]').val() === 'discovery';
  // toggle the field rows only — never .show() the help blockquotes, because
  // jQuery's show() force-sets display:block and would defeat .inline_help's
  // click-to-reveal (it must stay hidden until its label is clicked).
  $('dl.km-token').toggle(!discovery);
  $('dl.km-ad').toggle(discovery);
  // hide the inactive help outright; hand the active one back to CSS (collapsed)
  $('blockquote.km-token').css('display', discovery ? 'none' : '');
  $('blockquote.km-ad').css('display', discovery ? '' : 'none');
}

$(function(){
  // native Unraid toggle switches
  $('.km-switch').switchButton({ on_label: kt('On'), off_label: kt('Off'), labels_placement: 'right' });
  // basic/advanced view switch — label flips automatically via on/off labels
  $('.km-adv-toggle').switchButton({ on_label: kt('Advanced view'), off_label: kt('Basic view'), labels_placement: 'right' });

  // advanced block hidden initially; flies in/out like VM Manager's .advanced
  $('.km-adv').hide();
  $('.km-adv-toggle').change(function(){ $('.km-adv').toggle('slow'); });

  // connection mode field visibility
  km_mode();
  $('[name="CONN_MODE"]').change(km_mode);

  km_place_status();
  km_status_connect();
});
window.addEventListener('beforeunload', function(){ if(km_es){ km_es.close(); } if(km_ues){ km_ues.close(); } if(km_ss){ km_ss.close(); } });
