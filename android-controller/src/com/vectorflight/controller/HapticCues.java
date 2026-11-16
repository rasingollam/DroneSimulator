package com.vectorflight.controller;

/** Event detection only: never changes stick values or sends flight commands. */
public final class HapticCues {
    public static final int NONE = 0, CENTER = 1, LIMIT = 2, PICKUP = 3;
    private final int[] centerSide = new int[4];
    private final int[] limitSide = new int[4];
    private boolean throttleLow = true, throttleHigh;

    public void sync(float[] raw) {
        for (int i = 1; i < 4; i++) {
            centerSide[i] = Math.abs(raw[i]) >= 0.12f ? sign(raw[i]) : 0;
            limitSide[i] = Math.abs(raw[i]) >= 0.98f ? sign(raw[i]) : 0;
        }
        throttleLow = raw[0] <= 0.01f;
        throttleHigh = raw[0] >= 0.99f;
    }

    public int update(float[] raw) {
        int cue = NONE;
        for (int i = 1; i < 4; i++) {
            float magnitude = Math.abs(raw[i]);
            int side = sign(raw[i]);
            // Hysteresis avoids buzzing while a thumb trembles near neutral.
            if (centerSide[i] != 0 && (magnitude <= 0.04f || side != centerSide[i])) {
                cue = Math.max(cue, CENTER);
                centerSide[i] = 0;
            }
            if (magnitude >= 0.12f) centerSide[i] = side;
            if (magnitude <= 0.90f) limitSide[i] = 0;
            if (magnitude >= 0.98f && limitSide[i] != side) {
                cue = LIMIT;
                limitSide[i] = side;
            }
        }
        if (raw[0] > 0.06f) throttleLow = false;
        if (raw[0] < 0.94f) throttleHigh = false;
        if (raw[0] <= 0.01f && !throttleLow) { cue = LIMIT; throttleLow = true; }
        if (raw[0] >= 0.99f && !throttleHigh) { cue = LIMIT; throttleHigh = true; }
        return cue;
    }

    private static int sign(float value) { return value < 0 ? -1 : 1; }
}
