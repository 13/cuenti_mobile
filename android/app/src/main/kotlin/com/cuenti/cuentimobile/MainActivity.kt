package com.cuenti.cuentimobile

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Keep account balances out of the task-switcher thumbnail and out of
        // screenshots. The biometric app-lock guards a resume and privacy mode
        // blurs amounts on demand, but neither reaches the snapshot Android
        // takes of the window when the app goes to the background -- which is
        // the dashboard, in full, with every figure on it.
        //
        // The cost is deliberate: screenshots of the app are blocked outright.
        // FLAG_SECURE is the only mechanism that covers both surfaces on every
        // API level this app supports (minSdk 28); setRecentsScreenshotEnabled
        // handles only the thumbnail and only from API 33.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }
}
