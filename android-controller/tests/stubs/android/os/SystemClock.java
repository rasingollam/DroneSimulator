package android.os;

/** Desktop test substitute for Android's monotonic clock; excluded from the APK. */
public final class SystemClock {
    public static long elapsedRealtime() { return System.nanoTime() / 1_000_000; }
}
