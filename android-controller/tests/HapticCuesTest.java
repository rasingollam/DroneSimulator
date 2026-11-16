package com.vectorflight.controller;

public final class HapticCuesTest {
    private static int checks;
    private static void check(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
        checks++; System.out.println("PASS: " + label);
    }
    private static float[] axes(float throttle, float yaw, float pitch, float roll) {
        return new float[]{throttle, yaw, pitch, roll};
    }
    public static void main(String[] args) {
        HapticCues cues = new HapticCues();
        check(cues.update(axes(0, 0, 0, 0)) == HapticCues.NONE, "Idle sticks do not buzz");
        check(cues.update(axes(0, 0.4f, 0, 0)) == HapticCues.NONE, "Leaving neutral does not falsely signal a crossing");
        check(cues.update(axes(0, 0.02f, 0, 0)) == HapticCues.CENTER, "Returning yaw to neutral produces a center tick");
        for (int i = 0; i < 50; i++)
            check(cues.update(axes(0, i % 2 == 0 ? -0.035f : 0.05f, 0, 0)) == HapticCues.NONE,
                "Neutral jitter does not repeat feedback " + i);
        cues.sync(axes(0.5f, 0, 0.7f, 0));
        check(cues.update(axes(0.5f, 0, -0.6f, 0)) == HapticCues.CENTER, "Fast pitch crossing detects neutral between touch samples");
        cues.sync(axes(0.5f, 0, 0, -0.5f));
        check(cues.update(axes(0.5f, 0, 0, 0)) == HapticCues.CENTER, "Releasing roll produces a center tick");
        for (int axis = 1; axis < 4; axis++) {
            float[] raw = axes(0.5f, 0, 0, 0);
            cues.sync(raw); raw[axis] = 1;
            check(cues.update(raw) == HapticCues.LIMIT, "Axis " + axis + " positive full travel gives limit cue");
            check(cues.update(raw) == HapticCues.NONE, "Holding axis " + axis + " at its limit does not buzz repeatedly");
            raw[axis] = 0.95f; cues.update(raw); raw[axis] = 1;
            check(cues.update(raw) == HapticCues.NONE, "Axis " + axis + " edge jitter does not repeat limit cue");
            raw[axis] = 0.8f; cues.update(raw); raw[axis] = -1;
            check(cues.update(raw) == HapticCues.LIMIT, "Axis " + axis + " negative full travel gets priority over center");
        }
        cues.sync(axes(0.5f, 0, 0, 0));
        check(cues.update(axes(0.55f, 0, 0, 0)) == HapticCues.NONE, "Throttle midpoint has no false neutral cue");
        check(cues.update(axes(1, 0, 0, 0)) == HapticCues.LIMIT, "Full throttle produces a limit cue");
        check(cues.update(axes(1, 0, 0, 0)) == HapticCues.NONE, "Holding full throttle does not repeat feedback");
        cues.update(axes(0.8f, 0, 0, 0));
        check(cues.update(axes(1, 0, 0, 0)) == HapticCues.LIMIT, "Leaving a throttle limit re-arms its cue");
        check(cues.update(axes(0, 0, 0, 0)) == HapticCues.LIMIT, "Zero throttle produces a limit cue");
        check(cues.update(axes(0.005f, 0, 0, 0)) == HapticCues.NONE, "Low-throttle jitter does not repeat feedback");
        cues.sync(axes(0, 0, 0, 0));
        check(cues.update(axes(0, 0, 0, 0)) == HapticCues.NONE, "Programmatic reset can silently synchronize cues");
        ControlState controls = new ControlState();
        check(controls.down(10, true, 0, 0), "First left finger captures stick for pickup feedback");
        check(!controls.down(11, true, 0, 0), "Extra finger cannot falsely claim an occupied stick");
        System.out.println("HAPTIC CUE TESTS: " + checks + " PASSED");
    }
}
