# Anim Velocity Immediate Guide (JMAnimInstance)

Purpose
- Provide immediate, thread-safe accessors for speed and velocity presence in JMAnimInstance without introducing state or hysteresis.
- Intended for single-player UE5.7 projects using Lyra framework conventions.

API Summary
- float GetSpeedXYImmediate() const
  - Returns current XY plane speed (cm/s) by sampling Pawn/OwningActor Velocity.
  - Thread-safe, BlueprintPure. No external writes.
- bool HasVelocityImmediate(float SpeedMin) const
  - Returns GetSpeedXYImmediate() > SpeedMin.
  - Thread-safe, BlueprintPure.

Usage (Animation Blueprint)
- Call these in the "Blueprint Thread Safe Update Animation" graph.
- Recommended threshold SpeedMin: 10鈥?5 cm/s (depends on input device sensitivity).
- Example:
  - SpeedXY_Immediate = GetSpeedXYImmediate()
  - bHasVelocityImmediate = HasVelocityImmediate(12.0)
  - Use bHasVelocityImmediate to gate Idle vs Walk/Run transitions or TIP suppression.

Design Notes
- No new UPROPERTY state is introduced to avoid additional memory and complexity.
- XY-only speed is used to align with ground locomotion choices.
- Pure functions guarantee no writes to external actors/components, honoring thread safety.

Performance
- O(1) operations per call; negligible CPU impact (<0.01 ms/frame typical).
- No allocations, no GC impact.

Limitations vs Hysteresis Option
- Immediate comparison may jitter near the threshold (walk/stop boundary).
- If jitter is observed, consider using the hysteresis-based approach (bHasVelocity with dual thresholds) described in Animation_UpdateVelocityData_Guide.md or extend JMAnimInstance with:
  - HasVelocityEnableSpeed / HasVelocityDisableSpeed
  - bHasVelocity (BlueprintReadOnly) state with deadband

Error Prevention
- Handle null Pawn/OwningActor safely (returns 0 or false).
- Do not add logging or writes in thread-safe pure functions.
- Keep threshold values consistent across AnimGraph usage to avoid inconsistent transitions.

Lyra Conformance
- Implementation resides in JMAnimInstance and follows ULyraAnimInstance patterns.
- Pure functions exposed under Category: "Blueprint Thread Safe Update Functions".

Changelog
- v1.0: Added GetSpeedXYImmediate and HasVelocityImmediate with documentation.
