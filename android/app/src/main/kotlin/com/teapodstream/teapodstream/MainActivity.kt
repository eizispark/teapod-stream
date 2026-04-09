package com.teapodstream.teapodstream

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL = "com.teapodstream/vpn"
        private const val EVENT_CHANNEL = "com.teapodstream/vpn/events"
        private const val VPN_PERMISSION_REQUEST = 1001
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Event channel for native → Flutter events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(VpnEventStreamHandler)

        // Method channel for Flutter → native calls
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "connect" -> {
                        val xrayConfig = call.argument<String>("xrayConfig") ?: run {
                            result.error("INVALID_ARGS", "xrayConfig required", null)
                            return@setMethodCallHandler
                        }
                        val socksPort = call.argument<Int>("socksPort") ?: 10808
                        val socksUser = call.argument<String>("socksUser") ?: ""
                        val socksPassword = call.argument<String>("socksPassword") ?: ""
                        val excludedPackages = call.argument<List<String>>("excludedPackages") ?: emptyList()
                        val tunAddress = call.argument<String>("tunAddress") ?: "198.18.0.1"
                        val tunNetmask = call.argument<String>("tunNetmask") ?: "255.255.0.0"
                        val tunMtu = call.argument<Int>("tunMtu") ?: 1500
                        val tunDns = call.argument<String>("tunDns") ?: "1.1.1.1"
                        val enableUdp = call.argument<Boolean>("enableUdp") ?: true

                        requestVpnPermission(result) {
                            startVpnService(
                                xrayConfig, socksPort, socksUser, socksPassword,
                                excludedPackages, tunAddress, tunNetmask, tunMtu,
                                tunDns, enableUdp
                            )
                            result.success(null)
                        }
                    }

                    "disconnect" -> {
                        stopVpnService()
                        result.success(null)
                    }

                    "getStats" -> {
                        val stats = XrayVpnService.getStats()
                        result.success(stats)
                    }

                    "getAbi" -> {
                        result.success(android.os.Build.SUPPORTED_ABIS.firstOrNull() ?: "arm64-v8a")
                    }

                    "isBinaryReady" -> {
                        val xray = java.io.File(applicationInfo.nativeLibraryDir, "libxray.so")
                        val tun2socks = java.io.File(applicationInfo.nativeLibraryDir, "libtun2socks.so")
                        val geoip = java.io.File(filesDir, "geoip.dat")
                        val geosite = java.io.File(filesDir, "geosite.dat")
                        
                        // If geodata is missing, try to extract it now (it's fast)
                        if (!geoip.exists() || !geosite.exists()) {
                            XrayVpnService.prepareBinaries(this)
                        }
                        
                        result.success(xray.exists() && tun2socks.exists() && geoip.exists() && geosite.exists())
                    }

                    "prepareBinaries" -> {
                        Thread {
                            val success = XrayVpnService.prepareBinaries(this)
                            runOnUiThread { result.success(success) }
                        }.start()
                    }

                    "ping" -> {
                        val address = call.argument<String>("address") ?: ""
                        val port = call.argument<Int>("port") ?: 443
                        // Run ping in background thread
                        Thread {
                            val latency = pingHost(address, port)
                            runOnUiThread { result.success(latency) }
                        }.start()
                    }

                    "getInstalledApps" -> {
                        Thread {
                            val apps = getInstalledApps()
                            runOnUiThread { result.success(apps) }
                        }.start()
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private var pendingVpnAction: (() -> Unit)? = null

    private fun requestVpnPermission(result: MethodChannel.Result, action: () -> Unit) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            // Need to ask for permission
            pendingResult = result
            pendingVpnAction = action
            startActivityForResult(intent, VPN_PERMISSION_REQUEST)
        } else {
            // Already have permission
            action()
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_PERMISSION_REQUEST) {
            if (resultCode == Activity.RESULT_OK) {
                pendingVpnAction?.invoke()
                pendingVpnAction = null
                pendingResult = null
            } else {
                pendingResult?.error("VPN_PERMISSION_DENIED", "User denied VPN permission", null)
                pendingResult = null
                pendingVpnAction = null
            }
        }
    }

    private fun startVpnService(
        xrayConfig: String,
        socksPort: Int,
        socksUser: String,
        socksPassword: String,
        excludedPackages: List<String>,
        tunAddress: String,
        tunNetmask: String,
        tunMtu: Int,
        tunDns: String,
        enableUdp: Boolean,
    ) {
        val intent = Intent(this, XrayVpnService::class.java).apply {
            action = XrayVpnService.ACTION_CONNECT
            putExtra(XrayVpnService.EXTRA_XRAY_CONFIG, xrayConfig)
            putExtra(XrayVpnService.EXTRA_SOCKS_PORT, socksPort)
            putExtra(XrayVpnService.EXTRA_SOCKS_USER, socksUser)
            putExtra(XrayVpnService.EXTRA_SOCKS_PASSWORD, socksPassword)
            putExtra(XrayVpnService.EXTRA_EXCLUDED_PACKAGES, ArrayList(excludedPackages))
            putExtra(XrayVpnService.EXTRA_TUN_ADDRESS, tunAddress)
            putExtra(XrayVpnService.EXTRA_TUN_NETMASK, tunNetmask)
            putExtra(XrayVpnService.EXTRA_TUN_MTU, tunMtu)
            putExtra(XrayVpnService.EXTRA_TUN_DNS, tunDns)
            putExtra(XrayVpnService.EXTRA_ENABLE_UDP, enableUdp)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopVpnService() {
        val intent = Intent(this, XrayVpnService::class.java).apply {
            action = XrayVpnService.ACTION_DISCONNECT
        }
        startService(intent)
    }

    private fun pingHost(address: String, port: Int): Int? {
        return try {
            val start = System.currentTimeMillis()
            val socket = java.net.Socket()
            socket.connect(java.net.InetSocketAddress(address, port), 5000)
            val elapsed = (System.currentTimeMillis() - start).toInt()
            socket.close()
            elapsed
        } catch (e: Exception) {
            null
        }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val packages = pm.getInstalledPackages(0)
        return packages
            .filter { it.packageName != packageName } // exclude self
            .mapNotNull { pkg ->
                try {
                    val appInfo = pkg.applicationInfo ?: return@mapNotNull null
                    val appName = pm.getApplicationLabel(appInfo).toString()
                    mapOf(
                        "packageName" to pkg.packageName,
                        "appName" to appName,
                    )
                } catch (e: Exception) {
                    null
                }
            }
            .sortedBy { it["appName"] }
    }
}
