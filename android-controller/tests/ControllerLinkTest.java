package com.vectorflight.controller;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.function.BooleanSupplier;
import org.json.JSONObject;

/** Runs the exact APK networking source against a real local Godot process. */
public final class ControllerLinkTest {
    private static int checks;
    private static void until(BooleanSupplier condition, String label) throws Exception {
        long deadline = System.currentTimeMillis() + 4000;
        while (!condition.getAsBoolean() && System.currentTimeMillis() < deadline) Thread.sleep(20);
        if (!condition.getAsBoolean()) throw new AssertionError(label);
        checks++; System.out.println("PASS: " + label);
    }
    public static void main(String[] args) throws Exception {
        Path statusFile = Paths.get(args[0]), doneFile = Paths.get(args[1]);
        ControlState controls = new ControlState();
        ControllerLink link = new ControllerLink(controls);
        try {
            JSONObject status = new JSONObject(new String(Files.readAllBytes(statusFile), StandardCharsets.UTF_8));
            link.connect("127.0.0.1", status.getString("pin"));
            until(() -> link.connected && link.paused && !link.armed, "APK sender pairs with the real Godot receiver");
            link.action("resume");
            until(() -> !link.paused, "Acknowledged Start command resumes the PC");
            link.action("arm");
            until(() -> link.armed, "Acknowledged Arm command enables motors");
            controls.down(10, true, 200, 500);
            controls.move(10, 200, 331, 130);
            controls.up(10);
            until(() -> link.height > 0.6, "Actual Java analog packets lift the simulated drone");
            link.action("camera");
            until(() -> link.fpv, "Camera command round-trips to phone telemetry");
            link.action("mode");
            until(() -> link.acro, "Flight mode command round-trips to phone telemetry");
            link.action("pause");
            until(() -> link.paused, "Phone pause freezes the simulator");
            link.action("reset");
            until(() -> !link.armed && controls.output()[0] == 0, "Remote reset clears phone throttle and PC arming");
            link.action("resume");
            until(() -> !link.paused, "Resume works after reset");
            link.action("arm");
            until(() -> link.armed, "Re-arm works after reset");
            link.stop();
            Thread.sleep(900);
            JSONObject after = new JSONObject(new String(Files.readAllBytes(statusFile), StandardCharsets.UTF_8));
            if (after.getBoolean("connected") || after.getBoolean("armed") || !after.getBoolean("paused"))
                throw new AssertionError("Link loss did not pause/disarm the actual host");
            checks++; System.out.println("PASS: Closing APK sender triggers the actual PC disconnect failsafe");
            System.out.println("JAVA/GODOT END-TO-END: " + checks + " PASSED");
        } finally {
            link.stop();
            Files.write(doneFile, new byte[]{1});
        }
    }
}
