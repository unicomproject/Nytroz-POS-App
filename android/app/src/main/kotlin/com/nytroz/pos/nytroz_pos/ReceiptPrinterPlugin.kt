package com.nytroz.pos.nytroz_pos

import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import java.util.concurrent.atomic.AtomicReference

/**
 * Native bridge for Android USB Host and Bluetooth Classic (SPP) ESC/POS printers.
 * Blocking I/O runs off the main thread.
 */
class ReceiptPrinterPlugin private constructor(
    private val activity: MainActivity,
) : MethodChannel.MethodCallHandler {

    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val printLock = Any()
    private val channelName = "com.nytroz.pos/receipt_printer"
    private val permissionAction = "com.nytroz.pos.USB_PERMISSION"
    private val sppUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private var channel: MethodChannel? = null
    private val pendingUsbPermission = AtomicReference<MethodChannel.Result?>(null)
    private var bluetoothSocket: BluetoothSocket? = null
    private var connectedBluetoothAddress: String? = null

    private val usbPermissionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != permissionAction) return
            val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
            val result = pendingUsbPermission.getAndSet(null) ?: return
            mainHandler.post { result.success(granted) }
        }
    }

    fun attach(engine: FlutterEngine) {
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler(this)
        val filter = IntentFilter(permissionAction)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(usbPermissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            activity.registerReceiver(usbPermissionReceiver, filter)
        }
    }

    fun detach() {
        try {
            activity.unregisterReceiver(usbPermissionReceiver)
        } catch (_: Exception) {
        }
        channel?.setMethodCallHandler(null)
        channel = null
        closeBluetoothQuietly()
        pendingUsbPermission.getAndSet(null)?.let {
            mainHandler.post { it.success(false) }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> result.success(getCapabilities())
            "usbListDevices" -> runBg(result) { usbListDevices() }
            "usbHasPermission" -> {
                val deviceName = call.argument<String>("deviceName")
                result.success(usbHasPermission(deviceName))
            }
            "usbRequestPermission" -> {
                val deviceName = call.argument<String>("deviceName")
                usbRequestPermission(deviceName, result)
            }
            "usbWrite" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                runBg(result) { usbWrite(args) }
            }
            "bluetoothIsEnabled" -> result.success(bluetoothAdapter()?.isEnabled == true)
            "bluetoothListBonded" -> runBg(result) { bluetoothListBonded() }
            "bluetoothConnect" -> {
                val address = call.argument<String>("address") ?: ""
                val timeoutMs = (call.argument<Number>("timeoutMs") ?: 8000).toLong()
                runBg(result) { bluetoothConnect(address, timeoutMs) }
            }
            "bluetoothWrite" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                runBg(result) { bluetoothWrite(args) }
            }
            "bluetoothDisconnect" -> runBg(result) {
                closeBluetoothQuietly()
                mapOf("disconnected" to true)
            }
            else -> result.notImplemented()
        }
    }

    private fun getCapabilities(): Map<String, Any?> {
        val hasUsbHost = activity.packageManager.hasSystemFeature(PackageManager.FEATURE_USB_HOST)
        val hasBluetooth = activity.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)
        return mapOf(
            "platform" to "android",
            "usbHost" to hasUsbHost,
            "bluetoothClassic" to hasBluetooth,
            "sdkInt" to Build.VERSION.SDK_INT,
        )
    }

    private fun usbManager(): UsbManager =
        activity.getSystemService(Context.USB_SERVICE) as UsbManager

    private fun bluetoothAdapter(): BluetoothAdapter? {
        val manager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return manager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
    }

    private fun usbListDevices(): List<Map<String, Any?>> {
        val manager = usbManager()
        return manager.deviceList.values.mapNotNull { device ->
            val out = findBulkOutEndpoint(device) ?: return@mapNotNull null
            mapOf(
                "deviceName" to device.deviceName,
                "vendorId" to device.vendorId,
                "productId" to device.productId,
                "deviceClass" to device.deviceClass,
                "manufacturerName" to safeUsbString { device.manufacturerName },
                "productName" to safeUsbString { device.productName },
                "serialNumber" to if (manager.hasPermission(device)) {
                    safeUsbString { device.serialNumber }
                } else null,
                "hasPermission" to manager.hasPermission(device),
                "bulkOutEndpointAddress" to out.address,
                "maxPacketSize" to out.maxPacketSize,
            )
        }
    }

    private fun findDevice(deviceName: String?): UsbDevice? {
        if (deviceName.isNullOrBlank()) return null
        return usbManager().deviceList[deviceName]
    }

    private fun usbHasPermission(deviceName: String?): Boolean {
        val device = findDevice(deviceName) ?: return false
        return usbManager().hasPermission(device)
    }

    private fun usbRequestPermission(deviceName: String?, result: MethodChannel.Result) {
        val device = findDevice(deviceName)
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "USB device was not found.", null)
            return
        }
        val manager = usbManager()
        if (manager.hasPermission(device)) {
            result.success(true)
            return
        }
        if (!pendingUsbPermission.compareAndSet(null, result)) {
            result.error("PERMISSION_IN_PROGRESS", "A USB permission request is already pending.", null)
            return
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val intent = Intent(permissionAction).setPackage(activity.packageName)
        val pending = PendingIntent.getBroadcast(activity, 0, intent, flags)
        manager.requestPermission(device, pending)
    }

    private fun usbWrite(args: Map<*, *>): Map<String, Any?> {
        synchronized(printLock) {
            return usbWriteLocked(args)
        }
    }

    private fun usbWriteLocked(args: Map<*, *>): Map<String, Any?> {
        val vendorId = (args["vendorId"] as? Number)?.toInt()
            ?: throw PluginException("NOT_CONFIGURED", "USB vendorId is required.")
        val productId = (args["productId"] as? Number)?.toInt()
            ?: throw PluginException("NOT_CONFIGURED", "USB productId is required.")
        val deviceName = args["deviceName"] as? String
        val serialNumber = args["serialNumber"] as? String
        val timeoutMs = (args["timeoutMs"] as? Number)?.toInt() ?: 8000
        val bytes = when (val raw = args["bytes"]) {
            is ByteArray -> raw
            is List<*> -> ByteArray(raw.size) { i -> (raw[i] as Number).toByte() }
            else -> throw PluginException("INVALID_ARGUMENT", "bytes payload is required.")
        }
        if (bytes.isEmpty()) {
            throw PluginException("INVALID_ARGUMENT", "Cannot write an empty ESC/POS payload.")
        }

        val candidates = usbManager().deviceList.values.filter {
            it.vendorId == vendorId && it.productId == productId
        }
        if (candidates.isEmpty()) {
            throw PluginException("DEVICE_NOT_FOUND", "Configured USB printer is not attached.")
        }
        val device = when {
            !deviceName.isNullOrBlank() ->
                candidates.firstOrNull { it.deviceName == deviceName }
                    ?: throw PluginException(
                        "DEVICE_NOT_FOUND",
                        "Configured USB deviceName was not found among matching VID/PID devices.",
                    )
            !serialNumber.isNullOrBlank() -> {
                val withSerial = candidates.filter { usbManager().hasPermission(it) }
                    .filter { safeUsbString { it.serialNumber } == serialNumber }
                when {
                    withSerial.size == 1 -> withSerial.first()
                    withSerial.isEmpty() -> throw PluginException(
                        "DEVICE_NOT_FOUND",
                        "Configured USB serial was not found (permission may be missing).",
                    )
                    else -> throw PluginException(
                        "MULTIPLE_DEVICES",
                        "Multiple USB printers match the configured identity.",
                    )
                }
            }
            candidates.size == 1 -> candidates.first()
            else -> throw PluginException(
                "MULTIPLE_DEVICES",
                "Multiple USB printers match vendor/product. Configure deviceName or serialNumber.",
            )
        }

        val manager = usbManager()
        if (!manager.hasPermission(device)) {
            throw PluginException("PERMISSION_DENIED", "USB permission is not granted for the printer.")
        }

        val endpointInfo = findBulkOutInterface(device)
            ?: throw PluginException("ENDPOINT_UNAVAILABLE", "No USB bulk OUT endpoint was found.")
        val connection = manager.openDevice(device)
            ?: throw PluginException("CONNECTION_FAILED", "Unable to open the USB device.")

        var claimed = false
        try {
            if (!connection.claimInterface(endpointInfo.intf, true)) {
                throw PluginException("INTERFACE_CLAIM_FAILED", "Unable to claim the USB interface.")
            }
            claimed = true
            val written = writeUsbChunks(
                connection,
                endpointInfo.endpoint,
                bytes,
                timeoutMs.coerceIn(1000, 60000),
            )
            if (written != bytes.size) {
                throw PluginException(
                    "PARTIAL_WRITE",
                    "USB write incomplete: wrote $written of ${bytes.size} bytes.",
                )
            }
            return mapOf(
                "bytesWritten" to written,
                "deviceName" to device.deviceName,
                "vendorId" to device.vendorId,
                "productId" to device.productId,
            )
        } finally {
            if (claimed) {
                try {
                    connection.releaseInterface(endpointInfo.intf)
                } catch (_: Exception) {
                }
            }
            try {
                connection.close()
            } catch (_: Exception) {
            }
        }
    }

    private data class BulkOutInterface(
        val intf: android.hardware.usb.UsbInterface,
        val endpoint: UsbEndpoint,
    )

    private fun findBulkOutEndpoint(device: UsbDevice): UsbEndpoint? =
        findBulkOutInterface(device)?.endpoint

    private fun findBulkOutInterface(device: UsbDevice): BulkOutInterface? {
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            for (e in 0 until intf.endpointCount) {
                val endpoint = intf.getEndpoint(e)
                if (endpoint.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                    endpoint.direction == UsbConstants.USB_DIR_OUT
                ) {
                    return BulkOutInterface(intf, endpoint)
                }
            }
        }
        return null
    }

    private fun writeUsbChunks(
        connection: UsbDeviceConnection,
        endpoint: UsbEndpoint,
        bytes: ByteArray,
        timeoutMs: Int,
    ): Int {
        val packetSize = endpoint.maxPacketSize.coerceAtLeast(64)
        var offset = 0
        val deadline = System.currentTimeMillis() + timeoutMs
        while (offset < bytes.size) {
            val remainingTime = (deadline - System.currentTimeMillis()).toInt()
            if (remainingTime <= 0) {
                throw PluginException("TIMEOUT", "USB write timed out before all bytes were sent.")
            }
            val end = minOf(offset + packetSize, bytes.size)
            val chunk = bytes.copyOfRange(offset, end)
            val transferred = connection.bulkTransfer(endpoint, chunk, chunk.size, remainingTime)
            when {
                transferred < 0 ->
                    throw PluginException("WRITE_FAILED", "USB bulkTransfer failed with code $transferred.")
                transferred == 0 ->
                    throw PluginException("WRITE_FAILED", "USB bulkTransfer wrote zero bytes.")
                else -> offset += transferred
            }
        }
        return offset
    }

    private fun ensureBluetoothConnectPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val granted = ContextCompat.checkSelfPermission(
            activity,
            android.Manifest.permission.BLUETOOTH_CONNECT,
        ) == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            throw PluginException(
                "PERMISSION_DENIED",
                "BLUETOOTH_CONNECT permission is required to use Bluetooth printers.",
            )
        }
    }

    private fun bluetoothListBonded(): List<Map<String, Any?>> {
        ensureBluetoothConnectPermission()
        val adapter = bluetoothAdapter()
            ?: throw PluginException("UNSUPPORTED_PLATFORM", "Bluetooth adapter is unavailable.")
        if (!adapter.isEnabled) {
            throw PluginException("BLUETOOTH_DISABLED", "Bluetooth is turned off.")
        }
        @Suppress("MissingPermission")
        val bonded = adapter.bondedDevices ?: emptySet()
        return bonded.map { device ->
            mapOf(
                "address" to device.address,
                "name" to safeBtName(device),
                "bondState" to device.bondState,
                "type" to device.type,
            )
        }
    }

    private fun bluetoothConnect(address: String, timeoutMs: Long): Map<String, Any?> {
        ensureBluetoothConnectPermission()
        val normalized = address.trim().uppercase()
        if (normalized.isEmpty()) {
            throw PluginException("NOT_CONFIGURED", "Bluetooth printer address is required.")
        }
        val adapter = bluetoothAdapter()
            ?: throw PluginException("UNSUPPORTED_PLATFORM", "Bluetooth adapter is unavailable.")
        if (!adapter.isEnabled) {
            throw PluginException("BLUETOOTH_DISABLED", "Bluetooth is turned off.")
        }
        if (bluetoothSocket?.isConnected == true && connectedBluetoothAddress == normalized) {
            return mapOf("connected" to true, "address" to normalized, "reused" to true)
        }
        closeBluetoothQuietly()

        @Suppress("MissingPermission")
        val device = try {
            adapter.getRemoteDevice(normalized)
        } catch (_: IllegalArgumentException) {
            throw PluginException("DEVICE_NOT_FOUND", "Invalid Bluetooth address.")
        }

        adapter.cancelDiscovery()
        @Suppress("MissingPermission")
        val socket = try {
            device.createRfcommSocketToServiceRecord(sppUuid)
        } catch (error: IOException) {
            throw PluginException("CONNECTION_FAILED", "Unable to create RFCOMM socket: ${error.message}")
        }

        val future = executor.submit<BluetoothSocket> {
            @Suppress("MissingPermission")
            socket.connect()
            socket
        }
        try {
            val connected = future.get(timeoutMs.coerceIn(1000, 60000), TimeUnit.MILLISECONDS)
            bluetoothSocket = connected
            connectedBluetoothAddress = normalized
            return mapOf("connected" to true, "address" to normalized, "reused" to false)
        } catch (error: TimeoutException) {
            try {
                future.cancel(true)
            } catch (_: Exception) {
            }
            try {
                socket.close()
            } catch (_: Exception) {
            }
            throw PluginException("TIMEOUT", "Bluetooth connect timed out.")
        } catch (error: Exception) {
            try {
                socket.close()
            } catch (_: Exception) {
            }
            val root = error.cause ?: error
            throw PluginException("CONNECTION_FAILED", "Bluetooth connect failed: ${root.message}")
        }
    }

    private fun bluetoothWrite(args: Map<*, *>): Map<String, Any?> {
        ensureBluetoothConnectPermission()
        val address = (args["address"] as? String)?.trim()?.uppercase().orEmpty()
        val timeoutMs = (args["timeoutMs"] as? Number)?.toLong() ?: 8000L
        val bytes = when (val raw = args["bytes"]) {
            is ByteArray -> raw
            is List<*> -> ByteArray(raw.size) { i -> (raw[i] as Number).toByte() }
            else -> throw PluginException("INVALID_ARGUMENT", "bytes payload is required.")
        }
        if (bytes.isEmpty()) {
            throw PluginException("INVALID_ARGUMENT", "Cannot write an empty ESC/POS payload.")
        }
        synchronized(printLock) {
            if (bluetoothSocket?.isConnected != true || connectedBluetoothAddress != address) {
                bluetoothConnect(address, timeoutMs)
            }
            val socket = bluetoothSocket
                ?: throw PluginException("NOT_CONNECTED", "Bluetooth printer is not connected.")
            try {
                val output = socket.outputStream
                output.write(bytes)
                output.flush()
                return mapOf(
                    "bytesWritten" to bytes.size,
                    "address" to address,
                )
            } catch (error: IOException) {
                closeBluetoothQuietly()
                throw PluginException("WRITE_FAILED", "Bluetooth write failed: ${error.message}")
            }
        }
    }

    private fun closeBluetoothQuietly() {
        try {
            bluetoothSocket?.close()
        } catch (_: Exception) {
        }
        bluetoothSocket = null
        connectedBluetoothAddress = null
    }

    private fun safeUsbString(block: () -> String?): String? =
        try {
            block()?.trim()?.takeIf { it.isNotEmpty() }
        } catch (_: SecurityException) {
            null
        }

    @Suppress("MissingPermission")
    private fun safeBtName(device: BluetoothDevice): String? =
        try {
            device.name?.trim()?.takeIf { it.isNotEmpty() }
        } catch (_: SecurityException) {
            null
        }

    private fun runBg(result: MethodChannel.Result, block: () -> Any?) {
        executor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (error: PluginException) {
                mainHandler.post { result.error(error.code, error.message, null) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("WRITE_FAILED", error.message ?: error.toString(), null)
                }
            }
        }
    }

    private class PluginException(val code: String, message: String) : Exception(message)

    companion object {
        fun register(activity: MainActivity, engine: FlutterEngine): ReceiptPrinterPlugin {
            val plugin = ReceiptPrinterPlugin(activity)
            plugin.attach(engine)
            return plugin
        }
    }
}
