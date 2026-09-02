package com.cuenti.cuentimobile

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Keep account balances out of the app-switcher preview, which is
        // otherwise a full picture of the dashboard shown to anyone who
        // presses the recents button -- outside the biometric lock, which
        // only guards a resume, and privacy mode, which only blurs what is
        // on screen.
        //
        // How that is done differs by version, deliberately:
        //
        //   Android 13+  setRecentsScreenshotEnabled hides the preview and
        //                nothing else, so screenshots keep working.
        //   Android 12-  that API does not exist, and FLAG_SECURE is the
        //                only thing that hides the preview. It also blocks
        //                screenshots. Protecting the balances is worth more
        //                than the screenshots on those versions, so the old
        //                behaviour stays rather than leaving them exposed.
        //
        // The cost is an app that behaves differently on two phones. The
        // release note says which, so it is a surprise that has an
        // explanation rather than one that does not.
        val canHidePreviewAlone = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU

        // Before super.onCreate: FLAG_SECURE has to be in place before the
        // window shows its first frame.
        if (!canHidePreviewAlone) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }

        super.onCreate(savedInstanceState)

        if (canHidePreviewAlone) {
            setRecentsScreenshotEnabled(false)
        }
    }
}
