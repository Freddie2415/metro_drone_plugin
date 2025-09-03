package io.modacity.metro_drone_plugin.handlers

import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import app.metrodrone.domain.metrodrone.Metrodrone
import app.metrodrone.domain.metrodrone.SoundPlayer
import app.metrodrone.domain.metronome.Metronome
import app.metrodrone.domain.drone.Drone
import app.metrodrone.domain.metronome.soundgen.MetronomeSoundGen
import app.metrodrone.domain.drone.soundgen.DroneSoundGen
import app.metrodrone.domain.drone.soundgen.DronePulseGen
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import android.content.Context
import app.metrodrone.domain.clicker.MetronomeClicker
import app.metrodrone.domain.metronome.models.Subdivision
import app.metrodrone.domain.metronome.soundgen.MetronomeSoundTreeBuilder

class MetronomeChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    
    private val metrodrone: Metrodrone by lazy {
        val droneSoundGen = DroneSoundGen()
        val metronomeSoundTreeBuilder = MetronomeSoundTreeBuilder(context)
        val metronomeSoundGen = MetronomeSoundGen(metronomeSoundTreeBuilder)
        val dronePulseGen = DronePulseGen(droneSoundGen)
        val drone = Drone(droneSoundGen)
        val metronome = Metronome(metronomeSoundGen, dronePulseGen, drone)
        val metronomeSoundPlayer = SoundPlayer()
        val droneSoundPlayer = SoundPlayer()
        val clicker = MetronomeClicker()
        
        Metrodrone(metronome, drone, metronomeSoundPlayer, droneSoundPlayer, clicker)
    }
    
    var tickStreamHandler: MetronomeTickStreamHandler? = null
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "start" -> {
                handleStart(call, result)
            }
            "stop" -> {
                handleStop(call, result)
            }
            "tap" -> {
                handleTap(call, result)
            }
            "setBpm" -> {
                handleSetBpm(call, result)
            }
            "setSubdivision" -> {
                handleSetSubdivision(call, result)
            }
            "setTimeSignatureNumerator" -> {
                handleSetTimeSignatureNumerator(call, result)
            }
            "setTimeSignatureDenominator" -> {
                handleSetTimeSignatureDenominator(call, result)
            }
            "setNextTickType" -> {
                handleSetNextTickType(call, result)
            }
            "setDroneDurationRatio" -> {
                handleSetDroneDurationRatio(call, result)
            }
            "setTickTypes" -> {
                handleSetTickTypes(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleStart(call: MethodCall, result: MethodChannel.Result) {
        try {
            metrodrone.startMetronome()
            // Connect beat flow to tick stream handler
            tickStreamHandler?.let { handler ->
                CoroutineScope(Dispatchers.Main).launch {
                    metrodrone.beatFlow.collect { beatIndex ->
                        handler.sendTick(beatIndex + 1)
                    }
                }
            }
            result.success("Metronome started")
        } catch (e: Exception) {
            result.error("START_ERROR", "Failed to start metronome: ${e.message}", null)
        }
    }
    
    private fun handleStop(call: MethodCall, result: MethodChannel.Result) {
        try {
            metrodrone.stopMetronome()
            result.success("Metronome stopped")
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop metronome: ${e.message}", null)
        }
    }
    
    private fun handleTap(call: MethodCall, result: MethodChannel.Result) {
        // TODO: Implement tap tempo functionality
        result.success("tap")
    }
    
    private fun handleSetBpm(call: MethodCall, result: MethodChannel.Result) {
        val bpm = call.arguments as? Int
        if (bpm != null) {
            // TODO: Implement BPM setting
            result.success("BPM set to $bpm")
        } else {
            result.error("INVALID_ARGUMENTS", "BPM value missing", null)
        }
    }
    
    private fun handleSetSubdivision(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any>
        if (args != null) {
            val name = args["name"] as? String
            val description = args["description"] as? String
            val restPattern = args["restPattern"] as? List<Boolean>
            val durationPattern = args["durationPattern"] as? List<Double>
            
            if (name != null && description != null && restPattern != null && durationPattern != null) {
                // TODO: Implement subdivision setting
                result.success("Subdivision updated")
            } else {
                result.error("INVALID_ARGUMENTS", "setSubdivision values missing or incorrect", null)
            }
        } else {
            result.error("INVALID_ARGUMENTS", "Invalid argument format", null)
        }
    }
    
    private fun handleSetTimeSignatureNumerator(call: MethodCall, result: MethodChannel.Result) {
        val value = call.arguments as? Int
        if (value != null) {
            // TODO: Implement time signature numerator setting
            result.success("timeSignatureNumerator set to $value")
        } else {
            result.error("INVALID_ARGUMENTS", "timeSignatureNumerator value missing", null)
        }
    }
    
    private fun handleSetTimeSignatureDenominator(call: MethodCall, result: MethodChannel.Result) {
        val value = call.arguments as? Int
        if (value != null) {
            // TODO: Implement time signature denominator setting
            result.success("timeSignatureDenominator set to $value")
        } else {
            result.error("INVALID_ARGUMENTS", "timeSignatureDenominator value missing", null)
        }
    }
    
    private fun handleSetNextTickType(call: MethodCall, result: MethodChannel.Result) {
        val tickIndex = call.arguments as? Int
        if (tickIndex != null) {
            // TODO: Implement next tick type setting
            result.success("setNextTickType set to index: $tickIndex")
        } else {
            result.error("INVALID_ARGUMENTS", "setNextTickType tickIndex missing", null)
        }
    }
    
    private fun handleSetDroneDurationRatio(call: MethodCall, result: MethodChannel.Result) {
        val ratio = call.arguments as? Double
        if (ratio != null) {
            // TODO: Implement drone duration ratio setting
            result.success("DroneDurationRatio set to $ratio")
        } else {
            result.error("INVALID_ARGUMENTS", "DroneDurationRatio value missing", null)
        }
    }
    
    private fun handleSetTickTypes(call: MethodCall, result: MethodChannel.Result) {
        val tickTypes = call.arguments as? List<String>
        if (tickTypes != null) {
            // TODO: Implement tick types setting
            result.success("tickTypes set to $tickTypes")
        } else {
            result.error("INVALID_ARGUMENTS", "tickTypes value missing", null)
        }
    }
}