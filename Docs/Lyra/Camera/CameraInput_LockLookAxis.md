# Camera Input: Lock Look Axis Lifecycle (TopDown Ortho)

Status: Adopted

## Overview

This guideline defines how and when the Look axis input (mouse move / right stick) is locked while the Top-Down Orthographic camera mode is active, and restored when exiting back to the third-person view.

- Engine: Unreal Engine 5.6
- Project type: Single-player (no networking / no replication)
- Module: LyraGame (GameplayAbility: GA_ChangeView)

## Goals

1. Prevent camera rotation while in TopDown Ortho mode.
2. Ensure control rotation and camera distance reset behave deterministically when returning to third-person.
3. Avoid misinterpretation in subsequent GetViewRotation updates caused by lingering input ignore states.

## Lifecycle

### Enter Orthographic Mode

- Read the current look-ignore state from APlayerController:
  - `bSavedIgnoreLookInput = PC->IsLookInputIgnored()`
- Lock Look axis input:
  - `PC->SetIgnoreLookInput(true)`
- Push camera mode:
  - `SetCameraMode(TopDownOrthoCameraModeClass)`

### Exit Orthographic Mode

Order of operations (strict):
1. Restore Look input first:
   - `PC->SetIgnoreLookInput(bSavedIgnoreLookInput)`
2. Reset third-person control rotation:
   - `PC->SetControlRotation(FRotator(-45.0f, PawnYaw, 0.0f))`
3. Reset third-person camera distance via LyraPlayerCameraManager:
   - Compute scalar targeting 200cm based on PawnData min/max
   - `PCM->SetZoomTargetScalar(Scalar)`
4. Optional fallback (only if position does not snap as expected):
   - `PC->SetViewTargetWithBlend(Pawn, 0.0f)`

### Cancellation / Edge Cases

- On ability cancellation or abnormal exit, always perform restoration of Look input using the saved state.
- If `PlayerController` is null, skip restoration safely.

## Compatibility Notes

- Enhanced Input: Locking Look input affects `AddControllerYawInput` / `AddControllerPitchInput` paths; no IMC changes required.
- Character orientation: Lyra defaults (`bUseControllerRotationYaw = true`, `bOrientRotationToMovement = false`) mean movement will not re-orient the pawn while look is locked.
- No networking features are used.

## Performance Impact

- Negligible CPU overhead (boolean read/write, single function calls)
- No memory allocations; one transient boolean per ability instance

## Error Prevention

- Always restore using the previously saved value; do not hardcode `false`.
- Perform restoration before any control rotation or camera distance resets to ensure first-frame update correctness.
- Guard against null `PlayerController` / invalid `AvatarActor`.

## Ownership and Maintenance

- Owner: Gameplay Ability (GA_ChangeView)
- Review cadence: Align with camera system changes or input mapping updates