package com.vectorflight.controller;

import android.os.SystemClock;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketTimeoutException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayDeque;
import java.util.UUID;
import org.json.JSONObject;

/** 60 Hz full-state UDP, sequence rejection, acknowledged commands and link timeout. */
public final class ControllerLink {
    public static final int PORT = 42424;
    private final ControlState controls;
    private final int serverPort;
    private final ArrayDeque<String> commands = new ArrayDeque<>();
    private volatile int generation;
    private volatile DatagramSocket socket;
    public volatile boolean connected, armed, paused = true, acro, crashed, fpv;
    public volatile String status = "Tap CONNECT to pair with your PC";
    public volatile int rtt;
    public volatile double height, speed;
    public volatile int droneInches = 5;
    public volatile double hoverThrottle = 0.358;

    public ControllerLink(ControlState controls) { this(controls, PORT); }
    ControllerLink(ControlState controls, int serverPort) { this.controls = controls; this.serverPort = serverPort; }

    public synchronized void action(String command) {
        if (!connected) return;
        if (command.equals("arm") && (paused || controls.raw()[0] > 0.02f)) return;
        if (command.equals("disarm") || command.equals("reset")) {
            controls.reset(); commands.clear();
        }
        if (commands.size() < 16) commands.add(command);
        if (command.equals("pause")) controls.center();
    }

    public void connect(final String host, final String pin) {
        stop();
        final int run = generation;
        status = "Connecting to " + host + "…";
        Thread worker = new Thread(() -> loop(host, pin, run), "Vector-controller-UDP");
        worker.start();
    }

    public void stop() {
        generation++;
        connected = armed = false;
        paused = true;
        controls.reset();
        synchronized (this) { commands.clear(); }
        DatagramSocket old = socket;
        socket = null;
        if (old != null) old.close();
        status = "Disconnected · tap CONNECT";
    }

    private void loop(String host, String pin, int run) {
        DatagramSocket udp = null;
        try {
            InetAddress address = InetAddress.getByName(host);
            udp = new DatagramSocket();
            udp.connect(address, serverPort);
            udp.setSoTimeout(2);
            if (run != generation) return;
            socket = udp;
            String session = UUID.randomUUID().toString();
            long seq = 0, lastAck = 0, lastAckSeq = -1, actionId = 0;
            String pending = "";
            byte[] buffer = new byte[2048];
            DatagramPacket incoming = new DatagramPacket(buffer, buffer.length);
            while (run == generation) {
                long start = SystemClock.elapsedRealtime();
                if (lastAck == 0 || start - lastAck > 600) {
                    connected = armed = false; paused = true;
                    controls.reset();
                    synchronized (this) { commands.clear(); }
                    pending = "";
                    status = "Waiting · check PC address, code, Wi-Fi and firewall";
                }
                synchronized (this) {
                    // Reset/disarm supersede an unacknowledged earlier command.
                    String next = commands.peek();
                    if (next != null && (pending.isEmpty() || next.equals("disarm") || next.equals("reset"))) {
                        pending = commands.remove(); actionId++;
                    }
                }
                float[] values = controls.output();
                JSONObject packet = new JSONObject();
                packet.put("v", 1); packet.put("pin", pin); packet.put("session", session);
                packet.put("seq", ++seq); packet.put("sent", start);
                packet.put("throttle", values[0]); packet.put("yaw", values[1]);
                packet.put("pitch", values[2]); packet.put("roll", values[3]);
                packet.put("action", pending); packet.put("action_id", actionId);
                byte[] bytes = packet.toString().getBytes(StandardCharsets.UTF_8);
                udp.send(new DatagramPacket(bytes, bytes.length));
                for (int n = 0; n < 32; n++) {
                    try {
                        incoming.setLength(buffer.length);
                        udp.receive(incoming);
                    } catch (SocketTimeoutException done) { break; }
                    JSONObject reply = new JSONObject(new String(buffer, 0, incoming.getLength(), StandardCharsets.UTF_8));
                    if (reply.optInt("v") != 1 || !session.equals(reply.optString("session"))) continue;
                    long ackSeq = reply.optLong("seq", -1);
                    if (ackSeq <= lastAckSeq || ackSeq > seq) continue;
                    lastAckSeq = ackSeq;
                    lastAck = SystemClock.elapsedRealtime();
                    if (run != generation) return;
                    connected = true;
                    armed = reply.optBoolean("armed"); paused = reply.optBoolean("paused");
                    acro = reply.optBoolean("acro"); crashed = reply.optBoolean("crashed");
                    fpv = reply.optBoolean("fpv"); height = reply.optDouble("height"); speed = reply.optDouble("speed");
                    droneInches = reply.optInt("drone_inches", droneInches);
                    hoverThrottle = reply.optDouble("hover_throttle", hoverThrottle);
                    rtt = (int)Math.max(0, Math.min(9999, lastAck - reply.optLong("sent", lastAck)));
                    if (!armed) controls.reset();
                    if (reply.optLong("action_ack") >= actionId) pending = "";
                    status = crashed ? "IMPACT · tap RESET" : (paused ? "PAUSED · tap START / RESUME" : (armed ? "LIVE · fly with both thumbs" : "READY · tap ARM at zero throttle"));
                }
                long remaining = 16_666_667L - (SystemClock.elapsedRealtime() - start) * 1_000_000L;
                if (remaining > 0) Thread.sleep(remaining / 1_000_000L, (int)(remaining % 1_000_000L));
            }
        } catch (Exception failure) {
            if (run == generation) status = "Cannot connect: " + failure.getClass().getSimpleName();
        } finally {
            if (udp != null) udp.close();
            if (run == generation) {
                connected = armed = false; controls.reset();
            }
        }
    }
}
