package com.vectorflight.controller;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.nio.charset.StandardCharsets;
import java.util.function.BooleanSupplier;
import org.json.JSONObject;

/** Fault injection against the exact APK sender, using a local UDP peer. */
public final class ControllerRecoveryTest {
    static volatile boolean replies = true, armed = true, paused;
    static volatile boolean malformed;
    static volatile int received, disconnects;
    static int checks;

    static void check(boolean value, String label) {
        if (!value) throw new AssertionError(label);
        checks++; System.out.println("PASS: " + label);
    }
    static void until(BooleanSupplier value, String label) throws Exception {
        long deadline = System.nanoTime() + 4_000_000_000L;
        while (!value.getAsBoolean() && System.nanoTime() < deadline) Thread.sleep(10);
        check(value.getAsBoolean(), label);
    }
    static DatagramSocket peer(int port) throws Exception {
        DatagramSocket socket = new DatagramSocket(port);
        Thread worker = new Thread(() -> {
            byte[] bytes = new byte[4096];
            while (!socket.isClosed()) {
                try {
                    DatagramPacket packet = new DatagramPacket(bytes, bytes.length);
                    socket.receive(packet);
                    JSONObject request = new JSONObject(new String(bytes, 0, packet.getLength(), StandardCharsets.UTF_8));
                    received++;
                    if ("disconnect".equals(request.optString("action"))) disconnects++;
                    if (!replies) continue;
                    if (malformed) {
                        byte[] bad = "broken-datagram".getBytes(StandardCharsets.UTF_8);
                        socket.send(new DatagramPacket(bad,bad.length,packet.getSocketAddress()));
                        malformed = false;
                    }
                    JSONObject response = new JSONObject();
                    response.put("v",1); response.put("session",request.getString("session"));
                    response.put("seq",request.getLong("seq")); response.put("sent",request.getLong("sent"));
                    response.put("action_ack",request.getLong("action_id"));
                    response.put("armed",armed); response.put("paused",paused);
                    byte[] reply = response.toString().getBytes(StandardCharsets.UTF_8);
                    socket.send(new DatagramPacket(reply,reply.length,packet.getSocketAddress()));
                } catch (Exception failure) {
                    if (!socket.isClosed()) throw new RuntimeException(failure);
                }
            }
        }, "Recovery-test-peer");
        worker.setDaemon(true); worker.start();
        return socket;
    }
    public static void main(String[] args) throws Exception {
        DatagramSocket server = peer(0);
        int port = server.getLocalPort();
        ControlState controls = new ControlState();
        ControllerLink link = new ControllerLink(controls,port);
        try {
            link.connect("127.0.0.1","123456");
            until(() -> link.connected && link.armed,"Sender connects to its UDP peer");
            controls.down(1,true,200,400); controls.move(1,200,244,130); controls.up(1);
            check(controls.raw()[0]>0.59f,"Test has a nonzero retained throttle");
            malformed = true;
            until(() -> !malformed,"Peer injects a damaged telemetry datagram");
            Thread.sleep(150);
            check(link.connected && link.armed,"Damaged telemetry cannot terminate the sender");
            replies = false;
            Thread.sleep(850);
            check(link.connected && link.armed && controls.raw()[0]>0.59f,"850 ms telemetry stall preserves session and throttle");
            replies = true;
            until(() -> link.status.startsWith("LIVE"),"Telemetry recovery restores live status without re-arming");
            server.close();
            Thread.sleep(200);
            int beforeRestart = received;
            server = peer(port);
            until(() -> received > beforeRestart+3 && link.connected && link.status.startsWith("LIVE"),"Transient socket errors do not kill the sender thread");
            replies = false;
            Thread.sleep(2250);
            check(!link.connected && !link.armed && controls.raw()[0]==0,"Sustained loss clears power and arming");
            check(disconnects>0,"One-way telemetry loss sends an explicit neutral disconnect to the PC");
            armed = false; paused = true; replies = true;
            until(() -> link.connected && link.paused && !link.armed,"Hard-loss recovery stays paused and disarmed");
            check(controls.raw()[0]==0,"Hard-loss recovery cannot restore stale throttle");
            System.out.println("SENDER RECOVERY TESTS: "+checks+" PASSED");
        } finally { link.stop(); server.close(); }
    }
}
