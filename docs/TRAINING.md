# Pilot training

Open **F5 while disarmed**. Choose with Up/Down or click a row, then Enter or click Launch. Escape closes the menu. The map is one connected 2.4 km square landscape; the flight boundary is a 1.1 km radius from the original airfield. You can explore between districts without loading another map. Crossing the boundary returns to the current activity's launch pad.

## Start with control, then add speed

1. Choose a drone with F4, use Angle mode and calm air. Try the meadow **Hover box**: take off, fly into the outlined box and make small corrections. The target is centred 3 m above the meadow, with ±2 m horizontal and ±0.5 m vertical tolerance. Speed must stay below 0.7 m/s for ten uninterrupted seconds. Leaving the tolerance restarts the hold.
2. Try **Precision landing**. First take off above 1.5 m, then fly to the marked destination. Settle on that pad inside a 3.3 m square, upright and below 0.25 m/s for one second. Starting on the pad or merely flying through its location does not complete the lesson. Reduce throttle progressively rather than disarming from height.
3. Fly the **airfield** and **meadow figure eight** circuits. Aim for consistent turns and clean laps before chasing medals.
4. Progress to **pine slalom** and **lakeside bridge** for gap reading and low flight. Touching the water fails the flight; R recovers to the launch pad.
5. Practise **freight yard technical** and **quarry elevation run** for tighter gaps and vertical recovery. Quarry gates follow the flight path in three dimensions.
6. Use **cross-country explorer** to combine navigation, height control and longer turns. It visits every district.

Repeat exercises in light wind, then try Acro once you can recover orientation comfortably. Compare the 2/3/4/5-inch builds on the same course. The software is an engineering approximation and touch controls cannot reproduce a real radio's physical stick feel.

## Circuits and medals

Cross gate 01 in the forward direction to start. Follow the teal gate through every checkpoint and return through 01 to finish. Reverse, skipped and out-of-aperture crossings do not count. The drone's span is subtracted from the opening clearance. The timer uses simulation time, so pausing does not add time.

| Activity | Gold | Silver | Bronze |
| --- | --- | --- | --- |
| Airfield | ≤32 s | ≤50 s | Any completed lap |
| Meadow figure eight | ≤38 s | ≤60 s | Any completed lap |
| Pine slalom | ≤27 s | ≤45 s | Any completed lap |
| Freight yard | ≤32 s | ≤55 s | Any completed lap |
| Quarry elevation | ≤38 s | ≤65 s | Any completed lap |
| Lakeside bridge | ≤46 s | ≤75 s | Any completed lap |
| Cross-country | ≤160 s | ≤260 s | Any completed lap |

These are initial game targets, not real-pilot benchmarks or certification standards. Lessons receive a completion mark rather than a racing medal.

## Records and controls

Personal bests and completion counts are saved in Godot's application data as `user://training.cfg`. Each activity, drone size, Angle/Acro mode and wind setting has a separate record. Changing wind or mode restarts the scoring attempt without moving the aircraft. R retries from the current launch point. F5 and airframe changes require disarming.

Airborne time, distance and impact count are saved periodically, at results/impacts and on normal exit. Tests use isolated progress files. F3 provides the activity map and height above the physical surface below; F3 again hides the HUD. The original FPV camera mounting and field of view remain unchanged.

Use Android controller 1.3 with the updated PC simulator for brief signal-gap recovery. Choose the activity on the PC and use the phone's Start/Resume and Arm controls. A phone Resume command cannot close the PC training menu while you are choosing an activity. Short gaps hold physics and can recover automatically; a sustained two-second loss disarms and requires a deliberate restart.
