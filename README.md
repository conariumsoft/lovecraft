# lovecraft-VR
Virtual reality framework and toolkit for ROBLOX.

The API Documentation can be found at: https://scientiist.github.io/lovecraft/


TODO LIST:
- VRController Haptic Feedback (Rumble)
    - Haptic Feedback when pushing on walls
    - When slapping things with hand
        - Also add sound system that matches the slapped material
- VRHead Physical interactions (Prevent pushing head through walls)
- Can use the force in debugging mode
- Debug Information Wrist Watch?
- Ballistics Module
    - Determines properties such as the damage of a punch or slap.
    - Allow blunt-force weapons to have:
        - DamageVelocityScale
        - MinimumDamageVelocity (velocity required to damage)
        - MaximumDamage (max damage)
    - Bladed weapons when thrown will embed into the target proportionally to force (mass*accel)
- Work out details of Multiplayer VR. (Later!!)
- Movement system. (Favor joysticks over teleport)
- Climbing?
- 