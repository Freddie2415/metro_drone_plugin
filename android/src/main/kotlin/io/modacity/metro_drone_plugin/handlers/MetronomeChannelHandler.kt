package io.modacity.metro_drone_plugin.handlers

import android.os.Build
import android.util.Log
import app.metrodrone.domain.drone.models.DurationRatio
import app.metrodrone.domain.metrodrone.Metrodrone
import app.metrodrone.domain.metronome.models.SoundAccent
import app.metrodrone.domain.metronome.models.Subdivision
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MetronomeChannelHandler(private val metrodrone: Metrodrone) :
    MethodChannel.MethodCallHandler {
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

            "prepareAudioEngine" -> {
                handlePrepareAudioEngine(call, result)
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

            "configure" -> {
                handleConfigure(call, result)
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
        metrodrone.metronome.tap()
        result.success("tap")
    }

    private fun handlePrepareAudioEngine(call: MethodCall, result: MethodChannel.Result) {
        try {
            metrodrone.prepareAudioEngine()
            result.success("Audio engine prepared")
        } catch (e: Exception) {
            result.error("PREPARE_ERROR", "Failed to prepare audio engine: ${e.message}", null)
        }
    }

    private fun handleSetBpm(call: MethodCall, result: MethodChannel.Result) {
        val bpm = call.arguments as? Int
        if (bpm != null) {
            metrodrone.metronome.updateBpm(bpm)
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
                try {
                    val subdivision =
                        createSubdivisionFromArgs(name, description, restPattern, durationPattern)
                    metrodrone.metronome.updateSubdivision(subdivision)
                    result.success("Subdivision updated")
                } catch (e: Exception) {
                    result.error(
                        "SUBDIVISION_ERROR",
                        "Failed to create subdivision: ${e.message}",
                        null
                    )
                }
            } else {
                result.error(
                    "INVALID_ARGUMENTS",
                    "setSubdivision values missing or incorrect",
                    null
                )
            }
        } else {
            result.error("INVALID_ARGUMENTS", "Invalid argument format", null)
        }
    }

    private fun handleSetTimeSignatureNumerator(call: MethodCall, result: MethodChannel.Result) {
        val value = call.arguments as? Int
        if (value != null) {
            metrodrone.metronome.updateTactSize(value)
            result.success("timeSignatureNumerator set to $value")
        } else {
            result.error("INVALID_ARGUMENTS", "timeSignatureNumerator value missing", null)
        }
    }

    private fun handleSetTimeSignatureDenominator(call: MethodCall, result: MethodChannel.Result) {
        val value = call.arguments as? Int
        if (value != null) {
            metrodrone.metronome.updateBeatDuration(value)
            result.success("timeSignatureDenominator set to $value")
        } else {
            result.error("INVALID_ARGUMENTS", "timeSignatureDenominator value missing", null)
        }
    }

    private fun handleSetNextTickType(call: MethodCall, result: MethodChannel.Result) {
        val tickIndex = call.arguments as? Int
        if (tickIndex != null) {
            metrodrone.metronome.setNextTickType(tickIndex)
            result.success("setNextTickType set to index: $tickIndex")
        } else {
            result.error("INVALID_ARGUMENTS", "setNextTickType tickIndex missing", null)
        }
    }

    private fun handleSetDroneDurationRatio(call: MethodCall, result: MethodChannel.Result) {
        val ratio = call.arguments as? Double
        if (ratio != null) {
            metrodrone.drone.durationRatio = DurationRatio(value = ratio)
            metrodrone.metronome.onFieldUpdate?.invoke("droneDurationRatio", ratio)
            Log.d("Metronome", "Drone Duration Ratio: ${ratio}");
            result.success("DroneDurationRatio set to $ratio")
        } else {
            result.error("INVALID_ARGUMENTS", "DroneDurationRatio value missing", null)
        }
    }

    private fun handleSetTickTypes(call: MethodCall, result: MethodChannel.Result) {
        val tickTypes = call.arguments as? List<String>
        if (tickTypes != null) {
            try {
                // Map Dart TickType strings to Android SoundAccent enum values
                val soundAccents = tickTypes.map { tickTypeString ->
                    mapTickTypeToSoundAccent(tickTypeString)
                }

                // Update tick types in metronome using new method
                metrodrone.metronome.setTickTypes(soundAccents)
                result.success("tickTypes set successfully")
            } catch (e: Exception) {
                result.error("TICK_TYPES_ERROR", "Failed to set tick types: ${e.message}", null)
            }
        } else {
            result.error("INVALID_ARGUMENTS", "tickTypes value missing", null)
        }
    }

    private fun handleConfigure(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any>
        if (args == null) {
            result.error("INVALID_ARGUMENTS", "Invalid argument format for configure", null)
            return
        }

        try {
            // Update BPM if provided
            (args["bpm"] as? Int)?.let { bpm ->
                metrodrone.metronome.updateBpm(bpm)
            }

            // Update time signature numerator if provided
            (args["timeSignatureNumerator"] as? Int)?.let { numerator ->
                metrodrone.metronome.updateTactSize(numerator)
            }

            // Update time signature denominator if provided
            (args["timeSignatureDenominator"] as? Int)?.let { denominator ->
                metrodrone.metronome.updateBeatDuration(denominator)
            }

            // Update drone duration ratio if provided
            (args["droneDurationRatio"] as? Double)?.let { ratio ->
                metrodrone.drone.durationRatio = DurationRatio(value = ratio)
                metrodrone.metronome.onFieldUpdate?.invoke("droneDurationRatio", ratio)
            }

            // Update pulsar mode (isDroning) if provided
            (args["isDroning"] as? Boolean)?.let { isDroning ->
                metrodrone.metronome.updatePulsarMode(isDroning)
            }

            // Update tick types if provided
            (args["tickTypes"] as? List<*>)?.let { tickTypesList ->
                val tickTypes = tickTypesList.filterIsInstance<String>()
                val soundAccents = tickTypes.map { tickTypeString ->
                    mapTickTypeToSoundAccent(tickTypeString)
                }
                metrodrone.metronome.setTickTypes(soundAccents)
            }

            // Update subdivision if provided
            (args["subdivision"] as? Map<*, *>)?.let { subdivisionMap ->
                val name = subdivisionMap["name"] as? String
                val description = subdivisionMap["description"] as? String
                val restPattern = (subdivisionMap["restPattern"] as? List<*>)?.filterIsInstance<Boolean>()
                val durationPattern = (subdivisionMap["durationPattern"] as? List<*>)?.filterIsInstance<Double>()

                if (name != null && description != null && restPattern != null && durationPattern != null) {
                    val subdivision = createSubdivisionFromArgs(name, description, restPattern, durationPattern)
                    metrodrone.metronome.updateSubdivision(subdivision)
                }
            }

            result.success("Metronome configured successfully")
        } catch (e: Exception) {
            result.error("CONFIGURE_ERROR", "Failed to configure metronome: ${e.message}", null)
        }
    }

    private fun createSubdivisionFromArgs(
        name: String,
        description: String,
        restPattern: List<Boolean>,
        durationPattern: List<Double>
    ): Subdivision {
        // Create a map from Dart subdivision names to Kotlin enum values for efficient lookup
        val subdivisionMap = mapOf(
            "QUARTER NOTES" to Subdivision.QUARTER,
            "EIGHTH NOTES" to Subdivision.EIGHTH,
            "SIXTEENTH NOTES" to Subdivision.SIXTEENTH,
            "TRIPLET" to Subdivision.TRIPLET,
            "SWING" to Subdivision.SWING,
            "REST AND EIGHTH NOTE" to Subdivision.REST_AND_EIGHTH,
            "DOTTED EIGHTH AND SIXTEENTH" to Subdivision.DOTTED_EIGHTH_AND_SIXTEENTH,
            "16TH NOTE & DOTTED EIGHTH" to Subdivision.SIXTEENTH_AND_DOTTED_EIGHTH,
            "2 SIXTEENTH NOTES & EIGHTH NOTE" to Subdivision.TWO_SIXTEENTH_AND_EIGHTH,
            "EIGHTH NOTE & 2 SIXTEENTH NOTES" to Subdivision.EIGHTH_AND_TWO_SIXTEENTH,
            "16TH REST, 16TH NOTE, 16TH REST, 16TH NOTE" to Subdivision.SIXTEENTH_REST_SIXTEENTH_NOTE_SIXTEENTH_REST_SIXTEENTH_NOTE,
            "16TH NOTE, EIGHTH NOTE, 16TH NOTE" to Subdivision.SIXTEENTH_NOTE_EIGHTH_NOTE_SIXTEENTH_NOTE,
            "2 TRIPLETS & TRIPLET REST" to Subdivision.TWO_TRIPLETS_AND_TRIPLET_REST,
            "TRIPLET REST & 2 TRIPLETS" to Subdivision.TRIPLET_REST_AND_TWO_TRIPLETS,
            "TRIPLET REST, TRIPLET, TRIPLET REST" to Subdivision.TRIPLET_REST_TRIPLET_TRIPLET_REST,
            "QUINTUPLETS" to Subdivision.QUINTUPLETS,
            "SEPTUPLETS" to Subdivision.SEPTUPLETS
        )

        // Try to match by name first (exact match)
        val normalizedName = name.uppercase(Locale.ROOT)
        subdivisionMap[normalizedName]?.let { return it }

        // Try to match by title/description
        val normalizedDescription = description.uppercase(Locale.ROOT)
        Subdivision.values().find {
            it.title.uppercase(Locale.ROOT) == normalizedDescription
        }?.let { return it }

        // Log warning for debugging if no match found
        android.util.Log.w(
            "MetronomeChannelHandler",
            "No subdivision match found for name: '$name', description: '$description'. Using default."
        )

        return Subdivision.default
    }

    private fun mapTickTypeToSoundAccent(tickTypeString: String): SoundAccent {
        return when (tickTypeString) {
            "TickType.silence" -> SoundAccent.MUTE
            "TickType.regular" -> SoundAccent.DEFAULT
            "TickType.accent" -> SoundAccent.ACCENT
            "TickType.strongAccent" -> SoundAccent.STRONG
            else -> {
                Log.w("MetronomeChannelHandler", "Unknown tick type: $tickTypeString, using default")
                SoundAccent.DEFAULT
            }
        }
    }
}