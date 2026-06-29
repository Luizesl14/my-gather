import "dart:js_interop";

import "package:web/web.dart" as web;

// Browser fullscreen helpers (the "F11" experience) for Flutter web.
bool isFullscreen() => web.document.fullscreenElement != null;

void toggleFullscreen() {
  if (web.document.fullscreenElement != null) {
    web.document.exitFullscreen();
  } else {
    web.document.documentElement?.requestFullscreen();
  }
}

// Fires whenever fullscreen is entered/exited (incl. via Esc / F11), so the UI
// can keep its icon in sync.
void onFullscreenChange(void Function() handler) {
  web.document.addEventListener(
    "fullscreenchange",
    ((web.Event _) => handler()).toJS,
  );
}
