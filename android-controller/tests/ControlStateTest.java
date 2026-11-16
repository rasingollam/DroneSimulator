package com.vectorflight.controller;

public final class ControlStateTest {
    private static int checks;
    private static void check(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
        checks++; System.out.println("PASS: " + label);
    }
    private static boolean near(float a, float b) { return Math.abs(a - b) < 0.0001f; }
    public static void main(String[] args) {
        ControlState state = new ControlState();
        check(near(state.output()[0], 0), "Startup throttle is zero");
        state.down(12, true, 200, 500);
        check(near(state.output()[0], 0), "Touch-down never jumps the throttle");
        state.move(12, 330, 357, 130);
        check(near(state.raw()[0], 0.55f), "Upward drag sets proportional throttle");
        check(near(state.output()[1], 1), "Left stick right produces positive right yaw");
        state.down(29, false, 900, 360);
        state.move(29, 1030, 230, 130);
        check(near(state.output()[2], -1) && near(state.output()[3], 1), "Right stick supplies forward pitch and right roll");
        check(near(state.output()[0], 0.55f), "Two fingers control independent sticks");
        state.up(12);
        check(near(state.output()[0], 0.55f) && near(state.output()[1], 0), "Left release retains throttle and centers yaw");
        check(near(state.output()[2], -1), "Lifting one finger does not release the other");
        state.up(29);
        check(near(state.output()[2], 0) && near(state.output()[3], 0), "Right release centers pitch and roll");
        state.down(42, true, 100, 300);
        check(near(state.output()[0], 0.55f), "Re-gripping preserves throttle");
        state.move(42, 100, 1000, 130);
        check(near(state.output()[0], 0), "Throttle clamps at zero");
        state.move(42, -1000, -1000, 130);
        check(near(state.output()[0], 1) && near(state.output()[1], -1), "Axis outputs clamp at physical limits");
        state.center();
        check(near(state.output()[0], 1) && near(state.output()[1], 0), "Cancel centers axes while retaining throttle");
        state.reset();
        check(near(state.output()[0], 0), "Disconnect resets throttle");
        check(near(ControlState.curve(0.03f), 0), "Dead zone filters tiny finger movement");
        check(ControlState.curve(0.5f) < 0.5f && ControlState.curve(0.5f) > 0.25f, "Expo gives finer control around center");
        check(near(ControlState.curve(-0.5f), -ControlState.curve(0.5f)), "Response curve is symmetric");
        System.out.println("CONTROL TESTS: " + checks + " PASSED");
    }
}
