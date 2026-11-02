# flutter_callkit_incoming 3.1.6, patched for Taxista

Upstream 3.1.6 (the latest release) with iOS fixes found while tracing failed calls on real
iPhones (2026-11-02). Android is unchanged. Keep this copy until upstream ships the same fixes.

1. Ending a call reports THAT call. Upstream sent ACTION_CALL_ENDED / ACTION_CALL_DECLINE with
   `self.data` (the newest call the plugin saw), so ending a stale call made the app hang up the
   call it had just started (the "ends itself after 2 seconds" calls).
2. `endCall` / `callConnected` act on the id they are given. Upstream switched to the last
   PushKit call's id while `isFromPushKit` was set, leaving the requested call stuck in CallKit.
3. No force unwrap of `self.data` (CXStartCallAction coming from the system, endCall before any
   call): a missing value is built from the action's UUID instead of crashing the app.
Not patched here: a PushKit push whose id is not a UUID is still ignored by the plugin, and iOS
kills an app that receives a VoIP push and reports nothing. AppDelegate.swift therefore always
passes a valid UUID.
5. `showCallkitIncoming(_:fromPushKit:reported:)` says whether CallKit took the call, so the app
   confirms "ringing" only for a call really on screen and replaces a refused one with a stand-in
   (a VoIP push that ends with no reported call gets the app killed: SIGKILL 0xBAADCA11, seen on
   both apps on 2026-11-02 when they shared one iPhone and one UUID).
