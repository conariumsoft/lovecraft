# lovecraft-VR
Virtual reality framework and toolkit for ROBLOX.

The API Documentation can be found at: https://scientiist.github.io/lovecraft/


TODO LIST:

https://developer.roblox.com/en-us/api-reference/class/Stats
https://developer.roblox.com/en-us/api-reference/class/DebuggerManager

- Make base station work.
- Wrist Flick throwing (Angular Velocity)
- Rumble when slapping things with hand
    - Also add sound system that matches the slapped material
- Can use the force in debugging mode *
- Debug Information Wrist Watch? *
- Movement system. (Favor joysticks over teleport) (SnapTurn) *
- Climbing *
- Make body & camera physics based (Can push yourself around?)

- Object Weight Solver (For Grips N Shiet)

- Ballistics Module
    - Determines properties such as the damage of a punch or slap.
    - Allow blunt-force weapons to have:
        - DamageVelocityScale
        - MinimumDamageVelocity (velocity required to damage)
        - MaximumDamage (max damage)
    - Bladed weapons when thrown will embed into the target proportionally to force (mass*accel)