UE5.7 AnimBlueprint Thread-Safe Velocity Access Guidelines

Overview
- Goal: In single-player UE5.7 projects, read movement velocity and orientation safely on the Animation Worker Thread, and update AnimInstance members without cross-object access.
- Scope: Main AnimBP, Layer AnimBP, Property Access, Blueprint Thread Safe Update Functions.
- Constraints: No networking/replication/RPC, UE5.7 toolchain only, Windows target.

Key Principles
- Use Property Access to read Owner鈥檚 Pawn/Actor Velocity and ActorYaw in the Blueprint Thread Safe Update stage.
- Keep C++ functions pure or snapshot-based: pass all inputs as parameters; never access external objects inside thread-safe update functions.
- Centralize updates through one function: UpdateVelocityDataFromSnapshot.
- Reuse pure helpers for calculations to keep code simple and testable.

New C++ API (UJMAnimInstance)
- UpdateVelocityDataFromSnapshot(WorldVelocity, ActorYawDeg, bUseXYOnly=true, InVelocityZeroTolerance=1e-6)
  Updates WorldVelocity, LocalVelocity, Speed2D, bHasVelocity, MovementAngleDeg, and CurrentCardinalDirection based on input snapshots.
- ComputeSpeedXYFromVelocity(WorldVelocity)
- ComputeLocalVelocityXY(WorldVelocity, ActorYawDeg, bXYOnly=true)
- ComputeMovementAngleDegFromLocal(LocalVelocity)
- HasVelocityWithTolerance(SpeedXY, MinSpeed)

Recommended Blueprint Wiring (Main AnimBP)
1) In 鈥淏lueprint Thread Safe Update Animation鈥?
   - Read Velocity from Owner via Property Access (Pawn/Actor 鈫?Velocity).
   - Read ActorYaw via Property Access (ActorRotation.Yaw).
   - Call UpdateVelocityDataFromSnapshot(Velocity, ActorYaw) on your JMAnimInstance.
2) Optionally, use pure helpers for inline calculations if you prefer not to write members.
3) Avoid casting to main AnimBP or reading external components inside thread-safe functions.

Layer AnimBP Usage
- Read bHasVelocity, Speed2D, MovementAngleDeg, CurrentCardinalDirection via Property Access or interface inputs.
- For pure calculations, call Compute* helpers with Property Access inputs.
- Do NOT attempt to Set variables in AnimGraph nodes; use thread-safe update stage.

Performance Notes
- Property Access is zero-copy, read-only; significantly cheaper than casting per frame.
- Snapshot update avoids cross-thread safety risks and reduces cache misses.
- Use Stat Anim / Stat AnimGraph to verify low overhead (<0.05 ms/frame in typical cases).

Error Prevention Checklist
- Never call TryGetPawnOwner()/GetOwningActor()/GetMovementComponent() inside thread-safe update functions that write members.
- Prefer passing inputs from Property Access and compute locally.
- Refresh function signature pins in AnimBP after changing C++ function signatures.
- Clamp/normalize angles (UnwindDegrees) and zero Z when using XY-only logic.
- Use IsNearlyZero for speed tolerance checks.

Single-Player Project Rules
- No RPC or replication in AnimBP.
- Keep all filenames in English.
- Follow Documentation/UE5_6_Compile_Guide.md for build steps.

Verification
- Blueprint: Thread Safe Update runs without warnings; no cross-object writes.
- Runtime: Speed2D, bHasVelocity, and directions match movement; no 鈥淧roperty Access鈥?warnings.
- Cooked build: No FAnimCurveBufferAccess errors; stable FPS.

Maintenance
- Prefer pure helper functions to encapsulate math.
- Keep thresholds configurable in AnimInstance settings (e.g., MoveSpeedThresholdForDirectionHold).
