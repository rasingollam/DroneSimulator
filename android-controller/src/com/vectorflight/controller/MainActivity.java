package com.vectorflight.controller;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Build;
import android.os.Bundle;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.text.InputType;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import java.util.Locale;

public final class MainActivity extends Activity {
    private final ControlState controls = new ControlState();
    private final ControllerLink link = new ControllerLink(controls);
    private PadView pad;
    private SharedPreferences prefs;

    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON | WindowManager.LayoutParams.FLAG_FULLSCREEN);
        if (Build.VERSION.SDK_INT >= 28) {
            WindowManager.LayoutParams attrs = getWindow().getAttributes();
            attrs.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER;
            getWindow().setAttributes(attrs);
        }
        prefs = getSharedPreferences("connection", MODE_PRIVATE);
        pad = new PadView();
        setContentView(pad);
        immersive();
        pad.post(this::connectDialog);
    }

    private void immersive() {
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY |
            View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
    }
    @Override public void onWindowFocusChanged(boolean focused) { super.onWindowFocusChanged(focused); if (focused) immersive(); }
    @Override protected void onPause() { link.stop(); super.onPause(); }
    @Override protected void onDestroy() { link.stop(); super.onDestroy(); }
    @Override public void onBackPressed() {
        new AlertDialog.Builder(this).setTitle("Disconnect controller?")
            .setMessage("The PC will pause and disarm when the controller disconnects.")
            .setPositiveButton("Disconnect", (d, w) -> { link.stop(); finish(); })
            .setNegativeButton("Keep flying", null).show();
    }

    private void connectDialog() {
        // Opening connection settings relinquishes control immediately.
        link.stop();
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        int spacing = (int)(24 * getResources().getDisplayMetrics().density);
        layout.setPadding(spacing, spacing / 2, spacing, 0);
        TextView help = new TextView(this);
        help.setText("On your PC, launch Vector Flight Lab and press F2. Use the same private Wi-Fi network.");
        layout.addView(help);
        EditText host = new EditText(this);
        host.setSingleLine(true); host.setHint("PC address, e.g. 192.168.1.8");
        host.setInputType(InputType.TYPE_CLASS_PHONE);
        host.setText(prefs.getString("host", "")); layout.addView(host);
        EditText code = new EditText(this);
        code.setSingleLine(true); code.setHint("6-digit pairing code from PC");
        code.setInputType(InputType.TYPE_CLASS_NUMBER);
        code.setFilters(new android.text.InputFilter[]{new android.text.InputFilter.LengthFilter(6)});
        layout.addView(code);
        AlertDialog dialog = new AlertDialog.Builder(this).setTitle("Connect to your simulator")
            .setView(layout).setPositiveButton("Connect", null).setNegativeButton("Cancel", null).create();
        dialog.setOnShowListener(ignored -> dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(button -> {
            String address = host.getText().toString().trim();
            String pin = code.getText().toString().trim();
            if (!validIPv4(address)) { host.setError("Enter the PC's IPv4 address shown under F2"); return; }
            if (!pin.matches("[0-9]{6}")) { code.setError("Enter all six digits"); return; }
            prefs.edit().putString("host", address).apply();
            controls.reset(); link.connect(address, pin); dialog.dismiss(); immersive();
        }));
        dialog.show();
    }

    static boolean validIPv4(String value) {
        String[] parts = value.split("\\.", -1);
        if (parts.length != 4) return false;
        try { for (String part : parts) if (!part.matches("[0-9]{1,3}") || Integer.parseInt(part) > 255) return false; }
        catch (NumberFormatException e) { return false; }
        return true;
    }

    private final class PadView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final int ink = Color.rgb(225, 238, 233), muted = Color.rgb(125, 155, 158), teal = Color.rgb(110, 240, 206), amber = Color.rgb(237, 184, 107);
        private float scale = 1, dx, dy;
        private int buttonPointer = -1, pressedButton = -1;
        private final HapticCues cues = new HapticCues();
        private final StickHaptics haptics;
        private final RectF[] buttons = {new RectF(24, 626, 242, 694), new RectF(258, 626, 476, 694), new RectF(492, 626, 710, 694), new RectF(726, 626, 944, 694), new RectF(960, 626, 1256, 694), new RectF(1070, 25, 1256, 82), new RectF(552, 480, 728, 535), new RectF(838, 25, 1052, 82)};

        PadView() {
            super(MainActivity.this); setFocusable(true); setContentDescription("Two-stick drone controller");
            haptics = new StickHaptics(this, prefs.getBoolean("haptics", true));
            cues.sync(controls.raw());
        }

        private void label(Canvas c, String text, float x, float y, int size, int color, boolean bold) {
            paint.setStyle(Paint.Style.FILL); paint.setColor(color); paint.setTextSize(size);
            paint.setTypeface(bold ? Typeface.create("sans-serif-medium", Typeface.BOLD) : Typeface.create("sans-serif", Typeface.NORMAL));
            c.drawText(text, x, y, paint);
        }
        private void rect(Canvas c, RectF r, int color) { paint.setStyle(Paint.Style.FILL); paint.setColor(color); c.drawRoundRect(r, 10, 10, paint); }
        private void line(Canvas c, float x1, float y1, float x2, float y2, int color, float width) { paint.setColor(color); paint.setStrokeWidth(width); c.drawLine(x1, y1, x2, y2, paint); }

        @Override protected void onDraw(Canvas c) {
            super.onDraw(c);
            c.drawColor(Color.rgb(8, 22, 29));
            // Margin keeps controls away from display cutouts and gesture edges.
            scale = Math.min((getWidth() - 32f) / 1280f, (getHeight() - 24f) / 720f);
            dx = (getWidth() - 1280 * scale) / 2; dy = (getHeight() - 720 * scale) / 2;
            c.save(); c.translate(dx, dy); c.scale(scale, scale);
            label(c, "VECTOR", 24, 57, 31, ink, true);
            label(c, "TOUCH RADIO  /  MODE 2", 25, 82, 12, muted, true);
            label(c, link.connected ? "CONNECTED" : "OFFLINE", 550, 46, 14, link.connected ? teal : amber, true);
            label(c, link.connected ? link.rtt + " ms round trip  ·  60 Hz send" : "LOCAL WI-FI CONTROLLER", 550, 73, 13, muted, false);
            line(c, 24, 103, 1256, 103, Color.rgb(36, 61, 67), 1);
            float[] raw = controls.raw();
            if (!link.connected || !link.armed || link.paused) cues.sync(raw);
            stick(c, 285, 366, raw[1], 1 - raw[0] * 2, "LEFT STICK", "THROTTLE / YAW");
            stick(c, 995, 366, raw[3], raw[2], "RIGHT STICK", "PITCH / ROLL");
            label(c, String.format(Locale.US, "%02d%%", Math.round(raw[0] * 100)), 596, 231, 42, teal, true);
            label(c, "THROTTLE", 593, 256, 12, muted, true);
            label(c, link.armed ? "ARMED" : "DISARMED", link.armed ? 600 : 580, 320, 19, link.armed ? teal : amber, true);
            label(c, link.acro ? "ACRO / RATE" : "ANGLE / LEVEL", 575, 349, 14, ink, true);
            label(c, String.format(Locale.US, "%.1f m", link.height), 598, 407, 23, ink, false);
            label(c, String.format(Locale.US, "%.1f km/h", link.speed), 591, 438, 17, muted, false);
            label(c, "Drag from any point. Throttle stays when released.", 24, 593, 15, muted, false);
            String status = link.status;
            if (status.length() > 59) status = status.substring(0, 58) + "…";
            label(c, status, 24, 136, 17, link.connected ? teal : amber, true);
            drawButton(c, 0, link.paused ? "START / RESUME" : "PAUSE", false);
            drawButton(c, 1, link.armed ? "DISARM" : "ARM", true);
            drawButton(c, 2, "RESET", false);
            drawButton(c, 3, link.fpv ? "CHASE VIEW" : "FPV VIEW", false);
            drawButton(c, 4, link.acro ? "SWITCH TO ANGLE" : "SWITCH TO ACRO", false);
            drawButton(c, 5, "CONNECT", false);
            drawButton(c, 6, "HELP", false);
            drawButton(c, 7, !haptics.isAvailable() ? "NO VIBRATOR" : (haptics.isEnabled() ? "HAPTICS ON" : "HAPTICS OFF"), false);
            c.restore();
            postInvalidateOnAnimation();
        }

        private void drawButton(Canvas c, int i, String title, boolean accent) {
            RectF r = buttons[i];
            rect(c, r, accent ? (link.armed ? amber : teal) : (pressedButton == i ? Color.rgb(43, 76, 81) : Color.rgb(22, 45, 53)));
            paint.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD)); paint.setTextSize(15);
            float width = paint.measureText(title);
            label(c, title, r.centerX() - width / 2, r.centerY() + 6, 15, accent ? Color.rgb(7, 30, 34) : ink, true);
        }

        private void stick(Canvas c, float x, float y, float vx, float vy, String title, String subtitle) {
            label(c, title, x - 52, 173, 13, teal, true);
            paint.setStyle(Paint.Style.FILL); paint.setColor(Color.rgb(15, 34, 42)); c.drawCircle(x, y, 174, paint);
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(2); paint.setColor(Color.rgb(47, 78, 84)); c.drawCircle(x, y, 174, paint);
            c.drawRoundRect(new RectF(x - 130, y - 130, x + 130, y + 130), 16, 16, paint);
            line(c, x - 157, y, x + 157, y, Color.rgb(38, 66, 72), 1);
            line(c, x, y - 157, x, y + 157, Color.rgb(38, 66, 72), 1);
            for (int k = -2; k <= 2; k++) { line(c, x - 6, y + k * 65, x + 6, y + k * 65, muted, 1); }
            float knobX = x + vx * 130, knobY = y + vy * 130;
            paint.setStyle(Paint.Style.FILL); paint.setColor(Color.argb(30, 110, 240, 206)); c.drawCircle(knobX, knobY, 39, paint);
            paint.setColor(teal); c.drawCircle(knobX, knobY, 21, paint);
            paint.setColor(Color.rgb(8, 37, 38)); c.drawCircle(knobX, knobY, 5, paint);
            label(c, subtitle, x - 74, 566, 13, muted, true);
        }

        @Override public boolean onTouchEvent(MotionEvent event) {
            int action = event.getActionMasked(), index = event.getActionIndex();
            int id = event.getPointerId(index);
            float x = (event.getX(index) - dx) / scale, y = (event.getY(index) - dy) / scale;
            if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
                for (int i = 0; i < buttons.length; i++) if (buttons[i].contains(x, y)) {
                    if (buttonPointer == -1) { buttonPointer = id; pressedButton = i; }
                    return true;
                }
                if (link.connected && link.armed && !link.paused && y >= 182 && y < 552) {
                    boolean captured = false;
                    if (x > 105 && x < 465) captured = controls.down(id, true, x, y);
                    else if (x > 815 && x < 1175) captured = controls.down(id, false, x, y);
                    if (captured) { cues.sync(controls.raw()); haptics.pulse(HapticCues.PICKUP); }
                }
            } else if (action == MotionEvent.ACTION_MOVE) {
                if (link.connected && link.armed && !link.paused) {
                    for (int i = 0; i < event.getPointerCount(); i++)
                        controls.move(event.getPointerId(i), (event.getX(i) - dx) / scale, (event.getY(i) - dy) / scale, 130);
                    haptics.pulse(cues.update(controls.raw()));
                }
            } else if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP) {
                controls.up(id);
                if (link.connected && link.armed && !link.paused) haptics.pulse(cues.update(controls.raw()));
                if (id == buttonPointer) {
                    int button = pressedButton; buttonPointer = pressedButton = -1;
                    if (button >= 0 && buttons[button].contains(x, y)) { performClick(); clicked(button); }
                }
            } else if (action == MotionEvent.ACTION_CANCEL) {
                controls.center(); buttonPointer = pressedButton = -1;
                cues.sync(controls.raw());
            }
            return true;
        }
        @Override public boolean performClick() { super.performClick(); return true; }

        private void clicked(int button) {
            switch (button) {
                case 0: link.action(link.paused ? "resume" : "pause"); break;
                case 1: link.action(link.armed ? "disarm" : "arm"); break;
                case 2: link.action("reset"); break;
                case 3: link.action("camera"); break;
                case 4: link.action("mode"); break;
                case 5: connectDialog(); break;
                case 6:
                    controls.center(); link.action("pause");
                    new AlertDialog.Builder(MainActivity.this).setTitle("Your first touch-controlled flight")
                        .setMessage("1. Press F2 on the PC. CONNECT using its address and pairing code.\n\n2. Tap START / RESUME, then ARM.\n\n3. Drag your left thumb upward slowly to about 55% throttle. Release to keep that setting. Drag downward to descend. Left/right movement controls yaw.\n\n4. Drag your right thumb up/down for pitch, left/right for roll. Release to center.\n\nHAPTICS: A tap confirms stick pickup, a light tick marks neutral, and a stronger bump marks full travel. Throttle has feedback at zero/full, not at its midpoint. Turn feedback on/off with HAPTICS. Enable touch vibration in Android settings if needed. The phone vibrates as a whole; it cannot identify each thumb separately.\n\nANGLE self-levels; ACRO retains tilt. Start in ANGLE. Watch the PC screen while using both thumbs.\n\nRESET returns to the pad, disarmed. Closing or leaving the app pauses and disarms the PC after half a second. Use a real radio later for physical stick practice.")
                        .setPositiveButton("Got it", null).show();
                    break;
                case 7:
                    if (!haptics.isAvailable()) {
                        Toast.makeText(MainActivity.this, "This device does not report a vibration motor.", Toast.LENGTH_LONG).show();
                        break;
                    }
                    haptics.setEnabled(!haptics.isEnabled());
                    prefs.edit().putBoolean("haptics", haptics.isEnabled()).apply();
                    if (haptics.isEnabled() && !haptics.pulse(HapticCues.PICKUP))
                        Toast.makeText(MainActivity.this, "Enable touch vibration / haptic feedback in Android settings if you feel no tap.", Toast.LENGTH_LONG).show();
                    break;
                default: break;
            }
        }
    }
}
