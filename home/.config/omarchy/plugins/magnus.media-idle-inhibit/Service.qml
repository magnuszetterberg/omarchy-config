import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

// Keep the screensaver and the lock away while something is actually playing.
//
// The hyprland.lua idle_inhibit rules only cover a *fullscreen* browser or
// media player. Watching YouTube in an ordinary window still idles out, which
// is what this closes.
//
// MPRIS is the signal rather than raw PipeWire audio, on purpose: on this
// machine the Bluetooth sink sits in RUNNING permanently once the headphones
// connect, and the Godot editor holds an open, uncorked stream while it is
// silent -- either one would pin the machine awake forever. A player that
// reports PlaybackStatus=Playing is the thing we actually mean. Firefox,
// Chromium, mpv, VLC and Spotify all report it, and they flip back to Paused
// the moment playback stops.
//
// The inhibitor is the Wayland idle-inhibit protocol, so it suppresses the
// screensaver and the lock together -- the same way the fullscreen window
// rules do -- because omarchy's idle service runs its IdleMonitor with
// respectInhibitors.
Item {
  id: root

  // Injected by omarchy-shell (the first-party service loader).
  property var shell: null

  // Mpris.players only notifies when a player appears or disappears, so a
  // player flipping play/pause is picked up through this counter instead.
  property int playersRevision: 0

  // Testing/escape hatch, driven over IPC. Not persisted.
  property bool overrideActive: false
  property bool overrideValue: false

  readonly property var players: Mpris.players ? Mpris.players.values : []

  readonly property bool mediaPlaying: {
    root.playersRevision
    for (var i = 0; i < root.players.length; i++) {
      var p = root.players[i]
      if (p && p.isPlaying) return true
    }
    return false
  }

  readonly property bool inhibiting: root.overrideActive ? root.overrideValue : root.mediaPlaying

  function playingLabels() {
    var labels = []
    for (var i = 0; i < root.players.length; i++) {
      var p = root.players[i]
      if (p && p.isPlaying) labels.push(String(p.identity || p.desktopEntry || "player"))
    }
    return labels
  }

  onInhibitingChanged: console.log("omarchy media-idle-inhibit " + (root.inhibiting ? "on" : "off")
    + " [" + root.playingLabels().join(", ") + "]")

  Instantiator {
    model: root.players
    delegate: Connections {
      required property var modelData
      target: modelData
      function onIsPlayingChanged() { root.playersRevision += 1 }
    }
  }

  // The idle-inhibit protocol attaches an inhibitor to a surface, so the
  // service needs a window of its own. A 1x1 transparent layer surface with an
  // empty input region is invisible and never steals a click.
  PanelWindow {
    id: anchor
    anchors { top: true; left: true }
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "omarchy-media-idle-inhibit"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  }

  IdleInhibitor {
    window: anchor
    enabled: root.inhibiting
  }

  IpcHandler {
    target: "mediaidle"

    function status(): string {
      return JSON.stringify({
        inhibiting: root.inhibiting,
        mediaPlaying: root.mediaPlaying,
        playing: root.playingLabels(),
        players: root.players.length,
        override: root.overrideActive ? (root.overrideValue ? "on" : "off") : "none"
      })
    }

    function force(value: string): string {
      var v = String(value || "").toLowerCase()
      if (v === "on" || v === "true" || v === "1") {
        root.overrideActive = true
        root.overrideValue = true
      } else if (v === "off" || v === "false" || v === "0") {
        root.overrideActive = true
        root.overrideValue = false
      } else {
        root.overrideActive = false
        root.overrideValue = false
      }
      return root.inhibiting ? "inhibiting" : "idle-allowed"
    }
  }
}
