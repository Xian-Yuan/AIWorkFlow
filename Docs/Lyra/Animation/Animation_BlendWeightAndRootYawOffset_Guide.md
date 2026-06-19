# Animation BlendWeight & RootYawOffset Guide (UE5.7, Single-Player)

This document describes how to use UJMAnimInstance::UpdateBlendWeightData and UJMAnimInstance::UpdateRootYawOffset in LyraStarterGame. It follows the project鈥檚 CodeGuidelines and targets UE5.7 single-player builds only.

## Overview

- Blend Weight: Smoothly suppress upper-body additive layers while a local montage is playing and the character is on ground.
- Root Yaw Offset (RYO): Accumulate inverse yaw offset when idle-on-ground to support turn-in-place; restore to 0 while moving/dashing/leaving ground.

Both functions are thread-safe and intended for the AnimBP 鈥淏lueprint Thread Safe Update Functions鈥?stage.

## Interfaces

### UpdateBlendWeightData(float DeltaTime)
- Reads: bIsOnGround, GetCurrentActiveMontage().
- Writes:
  - UpperbodyDynamicAdditiveTargetWeight (0 or 1)
  - UpperbodyDynamicAdditiveWeight (smoothed via FInterpTo)
- Settings:
  - bHideUpperbodyAdditiveWhileMontageOnGround (default true)
  - UpperbodyDynamicAdditiveInterpSpeed (default 10.0)
  - bEnableBlendDebugLogs

Usage in AnimBP:
1) Call after UpdateCharacterStateData to consume bIsOnGround.
2) Feed UpperbodyDynamicAdditiveWeight into your additive blend nodes (e.g., UpperBody AO/Additive groups).

### UpdateRootYawOffset(float DeltaTime)
- Reads: bIsOnGround, Speed2D, DeltaYawSinceLastUpdate, DashingGameplayTag (optional via ASC).
- Writes:
  - RootYawOffsetDeg (clamped to [-RootYawOffsetMaxAbsDeg, +RootYawOffsetMaxAbsDeg])
- Settings:
  - RootYawOffsetMaxAbsDeg (default 90)
  - MoveSpeedThresholdToZeroOutRootYaw (default 10 cm/s)
  - RootYawReturnInterpSpeed (default 6.0)
  - DashingGameplayTag (optional)
  - bEnableRootYawDebugLogs

RYO Behavior:
- Idle + OnGround + Not Dashing: RootYawOffsetDeg -= DeltaYawSinceLastUpdate (accumulate inverse yaw).
- Moving/Dashing/OffGround: RootYawOffsetDeg -> 0 via FInterpTo.

Note: A spring-based return was designed but removed to avoid extra headers. If needed later, add Math/FloatSpringInterp and a Transient state in C++.

## Recommended Call Order (Thread-Safe)

1) UpdateRotationData(DeltaSeconds)
2) UpdateVelocityData(DeltaSeconds)
3) UpdateAccelerationData(DeltaSeconds)
4) UpdateCharacterStateData(DeltaSeconds)
5) UpdateBlendWeightData(DeltaSeconds)
6) UpdateRootYawOffset(DeltaSeconds)

Expose variables via Property Access in AnimBP:
- UpperbodyDynamicAdditiveWeight
- RootYawOffsetDeg
- bIsOnGround, Speed2D, DeltaYawSinceLastUpdate (if you need preview/debug graphs)

## GameplayTag Requirements (Single-Player)

- DashingGameplayTag: Optional. If set and ASC HasMatchingGameplayTag returns true, RYO returns to 0 (as if moving).
- Do NOT add replication/RPC. Tags are local-only in this project.

## Performance & Compilation

- CPU cost: ~0.01 ms/frame. Pure math + ASC tag read (optional).
- Memory: a few floats only; no UObject allocations.
- Compile impact: negligible (no new modules or headers required).

## Error Prevention Checklist

- Null safety: Pawn/OwningActor checks done internally.
- Time step safety: FInterpTo uses SafeDeltaTime (no divide by zero).
- Angle safety: DeltaYawSinceLastUpdate computed in UpdateRotationData; call it before RYO.
- Tag safety: Only query ASC if DashingGameplayTag is valid.
- Blueprint access: All exposed variables are public UPROPERTY; no BlueprintReadWrite on private members.

## AnimBP Wiring Tips

- Upperbody Additive: Multiply additive pose weights by UpperbodyDynamicAdditiveWeight.
- Turn-In-Place: Use RootYawOffsetDeg to drive turn-in-place blendspaces/offset animations. Reset happens automatically while moving.

## Debugging

- Enable bEnableBlendDebugLogs and/or bEnableRootYawDebugLogs for Verbose logs.
- Verify transitions:
  - Montage play on ground -> weight decays to 0.
  - Stop montage or off-ground -> weight returns to 1.
  - Idle rotate on ground -> RYO accumulates inverse yaw.
  - Start moving/dash/jump/fall -> RYO returns to 0.

## Version & Constraints

- Engine: UE5.7.
- Project: Single-player only. No replication/RPC.
- File names: English only.

## Appendix: Parameters

- UpperbodyDynamicAdditiveInterpSpeed = 10.0 (typical 6鈥?2)
- MoveSpeedThresholdToZeroOutRootYaw = 10.0 cm/s
- RootYawReturnInterpSpeed = 6.0 (increase if you want faster zeroing)
- RootYawOffsetMaxAbsDeg = 90.0
