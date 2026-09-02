package com.cuenti.cuentimobile

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep account balances out of the app-switcher preview, which was a
        // full picture of the dashboard sitting outside everything else that
        // protects it: the biometric lock only guards a resume, and privacy
        // mode only blurs what is on screen.
        //
        // 2.4.0 used FLAG_SECURE, which covers this on every API level but
        // also blocks screenshots of the app outright. This is the narrow
        // version: it hides the preview and leaves deliberate screenshots
        // working. The trade-off is that it exists only from Android 13, so
        // on 12 and below (minSdk 28) neither surface is protected.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setRecentsScreenshotEnabled(false)
        }
    }
}
