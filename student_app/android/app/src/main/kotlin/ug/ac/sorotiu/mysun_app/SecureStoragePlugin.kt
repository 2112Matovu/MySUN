package ug.ac.sorotiu.mysun_app

import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android Keystore-backed storage for the Supabase access/refresh tokens
 * (student_app/lib/core/network/token_storage.dart). Written in-house
 * rather than pulled from pub: `flutter_secure_storage` drags in
 * `path_provider`, which fails to build on this machine (project path has
 * a space, breaking its native-assets hook); `flutter_keychain` has no
 * version that's both readable by this JDK 17 toolchain (3.0.1 ships
 * Java 21 bytecode) and compatible with Flutter's current v2-only plugin
 * embedding (2.5.0 still calls the removed `Registrar` v1 API).
 * EncryptedSharedPreferences is a plain AndroidX library, not a Flutter
 * plugin, so neither problem applies.
 */
class SecureStoragePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var prefs: SharedPreferences

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        prefs = EncryptedSharedPreferences.create(
            context,
            "mysun_secure_prefs",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
        channel = MethodChannel(binding.binaryMessenger, "mysun/secure_storage")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key")
        when (call.method) {
            "get" -> result.success(prefs.getString(key, null))
            "put" -> {
                prefs.edit().putString(key, call.argument<String>("value")).apply()
                result.success(null)
            }
            "remove" -> {
                prefs.edit().remove(key).apply()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
