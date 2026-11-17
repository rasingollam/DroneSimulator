# Airframe comparison and evidence

The selector offers **representative open-prop builds**, not certified replicas or a universal model of every drone with that propeller size. A ducted cinewhoop, ultralight toothpick and heavy camera platform can handle very differently even with identical prop diameters. Battery, payload, motor and prop pitch matter too.

Press **F4** while disarmed to inspect the models. Use **2 / 3 / 4 / 5** to select, then Enter to return to the field. Direct number-key selection also works while disarmed. The Android 1.2 app adds an **AIRFRAME** button. Switching resets position, velocity, motors and the circuit, and never arms automatically. Best lap times are kept separately per airframe for the current session.

| Profile | Prop | All-up mass | Motor diagonal | Pack | Motor class | Thrust limit per motor | Spool time | Approx. hover |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MICRO 2 | 50.8 mm / 2 blades | 60 g | 95 mm | 2S 420 mAh | 1002 / 15500 KV | 0.80 N | 18 ms | 43% |
| SCOUT 3 | 76.2 mm / 3 blades | 125 g | 143 mm | 3S 550 mAh | 1104 / 4300 KV | 1.70 N | 25 ms | 42% |
| RANGE 4 | 101.6 mm / 2 blades | 229 g | 186 mm | 4S 750 mAh | 1404 / 2750 KV | 3.10 N | 35 ms | 43% |
| APEX 5 | 127.0 mm / 3 blades | 652 g | 245 mm | 6S 1400 mAh | 2207 / 1800 KV | 12.50 N | 45 ms | 36% |

## What is sourced and what is estimated?

- The 2-inch build is guided by Flywoo's [Firefly 2S Nano Baby 20](https://flywoo.net/products/firefly-2s-nano-baby-20-analog): the manufacturer lists 33.8 g without battery, 1002 15500 KV motors and two-blade 2015 props, and supports a 2S 420 mAh pack. The simulated 60 g ready-to-fly mass adds an **estimated** 26.2 g battery. The 95 mm frame and thrust limit are representative estimates, not verified measurements of that product.
- The light 3-inch class is guided by DarwinFPV's [BabyApe product family](https://darwinfpv.com/products/darwinfpv-babyape-3). This is a generic 1104/3S configuration, **not** a firmware/product replica. All-up mass includes an assumed battery; the chosen thrust, inertia and spool response are engineering estimates.
- The 4-inch explorer uses the approximate 229 g takeoff mass and 4S 750 mAh pack described for Flywoo's [Explorer LR 4 V2 O4 Wide](https://flywoo.net/products/explorer-lr4-o4-wide). Frame/motor class are informed by that family; the simulation does not model its electronics, GPS or battery endurance.
- The 5-inch class follows the 245 mm geometry, 652 g takeoff mass with 6S 1400 mAh battery, and 2207 1800 KV motor class listed by [iFlight for the Nazgul ECO XL5](https://shop.iflight.com/index.php?route=product/product&product_id=2923). The [manufacturer motor test sheet](https://iflight-public.oss-cn-hongkong.aliyuncs.com/Support/lnstructions/XING-E-MOTOR/XING-E-Pro-2207-1800KV-EN-1.pdf) is a hardware reference, **not a fitted thrust curve** in this simulator. The 12.5 N motor ceiling is a conservative representative estimate and is not presented as a measured value from that sheet.

The mass distribution/inertias, drag areas, rotor reaction coefficients, control gains and motor time constants for **all four** builds are estimated. There has been no real-flight log calibration. Profile pack voltage/capacity are configuration labels; battery discharge and voltage sag are not simulated. Motor KV is used to describe the chosen hardware class, not as a claim that KV alone predicts thrust.

## What physically changes?

The simulator changes mass, a positive physically admissible inertia tensor, motor locations/lever arms, thrust limits, motor response, reaction torque, aerodynamic drag areas, center-of-mass height and frame/battery collision envelopes. Visual frame and propeller dimensions change too. Controller torque gains scale with inertia; the stick rate limits are shared so comparisons are not distorted by arbitrary rate presets.

The light micro has a larger drag-to-mass ratio and lower momentum. The 5-inch setup has greater thrust-to-weight and kinetic energy. These effects arise from forces and inertia, not canned handling animations. The model includes bounded near-ground rotor lift and effective rotor-plane drag approximations, but not full blade-element aerodynamics, propwash or vortex-ring state.

Hover is calculated from `sqrt(m*g/(4*Tmax))` in free air. Close to the ground, the bounded ground-effect approximation can reduce the required power slightly. The H shortcut and phone HOVER label use the selected profile; neither provides altitude hold.

Automated checks run each profile through force balance, hover stability, pitch/yaw/roll response, self-leveling, Acro release, wind response, and disarmed switching. These establish internal consistency, not real-aircraft validation. Compare feel here as an initial guide, then use a real radio and measured configuration before treating it as training for a specific aircraft.
