class_name WebBridge
extends RefCounted
## Stable browser file download + JSON open for Godot Web exports.

static var _load_cb: JavaScriptObject = null
static var _on_text: Callable = Callable()


static func is_web() -> bool:
	return OS.has_feature("web")


static func ensure_load_hook(on_text: Callable) -> void:
	if not is_web():
		return
	_on_text = on_text
	if _load_cb != null:
		return
	_load_cb = JavaScriptBridge.create_callback(_js_load_callback)
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return
	window.ipmOnMapJson = _load_cb
	JavaScriptBridge.eval("""
(function(){
  if (window.__ipmPickerReady) return;
  window.__ipmPickerReady = true;
  window.ipmPickJson = function() {
    var input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json,application/json';
    input.style.display = 'none';
    document.body.appendChild(input);
    input.onchange = function(e) {
      var file = e.target.files && e.target.files[0];
      if (!file) { try { document.body.removeChild(input); } catch(_){} return; }
      var reader = new FileReader();
      reader.onload = function() {
        try {
          if (window.ipmOnMapJson) {
            // Godot JavaScriptBridge callback expects .apply(null, argsArray)
            if (typeof window.ipmOnMapJson.apply === 'function') {
              window.ipmOnMapJson.apply(null, [String(reader.result || '')]);
            } else if (typeof window.ipmOnMapJson === 'function') {
              window.ipmOnMapJson(String(reader.result || ''));
            }
          }
        } finally {
          try { document.body.removeChild(input); } catch(_){}
        }
      };
      reader.onerror = function() {
        try { document.body.removeChild(input); } catch(_){}
      };
      reader.readAsText(file);
    };
    input.click();
  };
})();
""")


static func _js_load_callback(args: Array) -> void:
	if args.is_empty():
		return
	var text := str(args[0])
	if text.length() < 2:
		return
	if _on_text.is_valid():
		_on_text.call(text)


static func pick_json() -> void:
	if not is_web():
		return
	JavaScriptBridge.eval("if (window.ipmPickJson) window.ipmPickJson();")


static func download_text(filename: String, text: String, mime: String = "application/json") -> void:
	if not is_web():
		return
	var b64 := Marshalls.utf8_to_base64(text)
	_download_b64(filename, b64, mime)


static func download_bytes(filename: String, buf: PackedByteArray, mime: String = "application/octet-stream") -> void:
	if not is_web():
		return
	var b64 := Marshalls.raw_to_base64(buf)
	_download_b64(filename, b64, mime)


static func _download_b64(filename: String, b64: String, mime: String) -> void:
	# Blob URL avoids giant data: URI limits on some browsers
	var js := """
(function(){
  try {
    var b64 = '%s';
    var bin = atob(b64);
    var len = bin.length;
    var bytes = new Uint8Array(len);
    for (var i = 0; i < len; i++) bytes[i] = bin.charCodeAt(i);
    var blob = new Blob([bytes], {type: '%s'});
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = '%s';
    document.body.appendChild(a);
    a.click();
    setTimeout(function(){
      try { URL.revokeObjectURL(url); } catch(_){}
      try { document.body.removeChild(a); } catch(_){}
    }, 1000);
  } catch (err) {
    console.error('ipm download failed', err);
  }
})();
""" % [b64, mime, filename]
	JavaScriptBridge.eval(js)
