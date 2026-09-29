package com.walkie.walkie

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Keep the FlutterEngine alive when the Activity is destroyed
    // (e.g. user swipes from recents). The foreground service keeps
    // the process alive, and this ensures WebRTC audio resources
    // (PeerConnections, AudioTrack) are NOT torn down.
    // When the user relaunches the app, the Activity re-attaches
    // to the existing engine.
    override fun shouldDestroyEngineWithHost(): Boolean = false
}
