package com.nytroz.pos.nytroz_pos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var receiptPrinterPlugin: ReceiptPrinterPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        receiptPrinterPlugin = ReceiptPrinterPlugin.register(this, flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        receiptPrinterPlugin?.detach()
        receiptPrinterPlugin = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
