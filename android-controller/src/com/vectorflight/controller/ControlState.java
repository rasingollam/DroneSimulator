package com.vectorflight.controller;

/** Pure control math, shared by the Android view and desktop unit checks. */
public final class ControlState {
    private float throttle, yaw, pitch, roll;
    private int leftId = -1, rightId = -1;
    private float leftX, leftY, rightX, rightY, startThrottle;
    public synchronized boolean down(int id, boolean left, float x, float y) {
        if (left && leftId < 0) {
            leftId = id; leftX = x; leftY = y; startThrottle = throttle; yaw = 0;
            return true;
        } else if (!left && rightId < 0) {
            rightId = id; rightX = x; rightY = y; pitch = roll = 0;
            return true;
        }
        return false;
    }
    public synchronized void move(int id, float x, float y, float travel) {
        if (id == leftId) {
            yaw = clamp((x - leftX) / travel, -1, 1);
            throttle = clamp(startThrottle - (y - leftY) / (2 * travel), 0, 1);
        }
        if (id == rightId) {
            roll = clamp((x - rightX) / travel, -1, 1);
            pitch = clamp((y - rightY) / travel, -1, 1);
        }
    }
    public synchronized void up(int id) {
        if (id == leftId) { leftId = -1; yaw = 0; }
        if (id == rightId) { rightId = -1; pitch = roll = 0; }
    }
    public synchronized void center() { leftId = rightId = -1; yaw = pitch = roll = 0; }
    public synchronized void reset() { center(); throttle = 0; }
    public synchronized float[] raw() { return new float[]{throttle, yaw, pitch, roll}; }
    public synchronized float[] output() { return new float[]{throttle, curve(yaw), curve(pitch), curve(roll)}; }
    static float curve(float value) {
        float magnitude = Math.abs(value);
        if (magnitude <= 0.04f) return 0;
        float x = (magnitude - 0.04f) / 0.96f;
        return Math.copySign(0.75f * x + 0.25f * x * x * x, value);
    }
    static float clamp(float value, float min, float max) { return Math.max(min, Math.min(max, value)); }
}
