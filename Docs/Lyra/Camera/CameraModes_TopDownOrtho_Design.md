# Camera Modes: TopDownOrtho and ThirdPerson (Controller Yaw Feeding)

This document describes how camera yaw feeds character orientation in TopDownOrtho and ThirdPerson modes, and how the character-side rotation strategy is implemented.

## Controller Yaw Feeding

- Camera systems provide controller yaw via `AController::GetControlRotation()`.
- Character uses controller yaw only when rotation gating enables `bUseControllerRotationYaw`.

## Character-Side Strategy

- Baseline: free-look (no controller yaw applied)
  - `bUseControllerRotationYaw = false`
  - `bOrientRotationToMovement = false`
  - `bUseControllerDesiredRotation = false`
- Movement-driven enable (event-driven via MovementComponent):
  - Enable when `Speed2D >= SpeedEnableThreshold` or `Accel2D >= AccelEnableThreshold`
  - Disable when both `Speed2D <= SpeedDisableThreshold` and `Accel2D <= AccelDisableThreshold`
  - First activation: snap actor yaw to controller yaw if delta exceeds `YawAlignToleranceDeg`

## Input Direction

- Input actions compute world-space movement direction using either controller yaw (camera-directed) or actor yaw (free-look), matching Enhanced Input setup.

## Tuning Per Mode

- TopDownOrtho:
  - Often stricter alignment; consider lower `YawAlignToleranceDeg` for snappier feel.
  - Keep `SpeedDisableThreshold` moderately high to avoid jitter after short bursts.
- ThirdPerson:
  - Softer alignment; keep tolerance around 2–3 degrees for smoothness.
  - Consider higher `SpeedEnableThreshold` to avoid accidental enables while strafing.

## Testing Checklist

- Idle: character remains free-look while rotating camera.
- Start moving: character aligns once, then follows camera yaw.
- Stop: character returns to free-look; no jitter near thresholds.
- Edge cases: slopes, small inputs, and falling behavior per design.