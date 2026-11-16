package com.vectorflight.controller;

import android.content.Context;
import android.os.SystemClock;
import android.os.Vibrator;
import android.view.HapticFeedbackConstants;
import android.view.View;

/** System-tuned touch effects, honoring Android's touch-feedback settings. */
public final class StickHaptics {
    private final View view;
    private final boolean available;
    private boolean enabled;
    private long lastPulse = -1000;

    public StickHaptics(View view, boolean enabled) {
        this.view = view;
        this.enabled = enabled;
        Vibrator vibrator = (Vibrator)view.getContext().getSystemService(Context.VIBRATOR_SERVICE);
        available = vibrator != null && vibrator.hasVibrator();
        view.setHapticFeedbackEnabled(true);
    }

    public boolean isAvailable() { return available; }
    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }

    public boolean pulse(int cue) {
        if (cue == HapticCues.NONE || !enabled || !available) return false;
        long now = SystemClock.elapsedRealtime();
        // One shared actuator cannot convey simultaneous axis events separately.
        if (now - lastPulse < 90) return false;
        lastPulse = now;
        int effect = cue == HapticCues.LIMIT ? HapticFeedbackConstants.LONG_PRESS
            : (cue == HapticCues.PICKUP ? HapticFeedbackConstants.VIRTUAL_KEY : HapticFeedbackConstants.CLOCK_TICK);
        boolean played = view.performHapticFeedback(effect);
        if (!played && effect == HapticFeedbackConstants.CLOCK_TICK)
            played = view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP);
        return played;
    }
}
