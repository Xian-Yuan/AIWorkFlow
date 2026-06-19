# Camera Movement Rotation Mode Guide (UE5.7 Single-Player)

This guide documents Scheme 1 for achieving a "Zenless Zone Zero"-style control mode in UE5.7 single-player projects:

- When the player has movement input: the character rotates toward the camera-space movement vector (like enabling "Use Controller Rotation Yaw" effect for movement), providing camera-directed movement.
- When the player has no movement input: the camera can freely rotate around the character, while the character yaw remains stable (like disabling "Use Controller Rotation Yaw").

涓枃鐗堟憳瑕侊細褰撴湁绉诲姩杈撳叆鏃讹紝瑙掕壊闈㈠悜鐩告満鏂瑰悜骞剁Щ鍔紱褰撴病鏈夌Щ鍔ㄨ緭鍏ユ椂锛屾憚鍍忔満鍙嚜鐢辩幆缁曪紝瑙掕壊涓嶅彈鎺у埗鍣╕aw寮虹粦銆傝妯″紡鍦║E5.6涓€氳繃 CharacterMovement銆丼pringArm 鍜?Enhanced Input 鐨勭粍鍚堥厤缃疄鐜帮紝绾湰鍦般€侀浂缃戠粶鍔熻兘銆?
## Version and Constraints
- Engine: Unreal Engine 5.6
- Project type: Single-player only, NO networking/RPC
- Platform: Windows (tested), others likely fine
- Blueprint-friendly: Yes, can be implemented in BP or C++

## Core Settings
Configure your player character and camera components:

1) Character
- `bUseControllerRotationYaw = false`
- `CharacterMovement->bOrientRotationToMovement = true`
- `CharacterMovement->bUseControllerDesiredRotation = false`
- `CharacterMovement->RotationRate.Yaw = 540鈥?20` (recommended: 720)

2) SpringArm / Camera
- `SpringArm->bUsePawnControlRotation = true` (camera follows controller rotation for free look)

Rationale:
- OrientRotationToMovement rotates the character toward acceleration/move direction; it overrides UseControllerDesiredRotation. Clearing bUseControllerRotationYaw avoids hard binding actor yaw to controller yaw when idle.

## Enhanced Input: IA_Move (Vector2D)
Use the controller's control rotation yaw to map your 2D input to camera-space world vectors.

Pseudo steps (BP or C++):
1. Read `Move` from IA_Move (Vector2D)
2. Compute `Yaw = Controller.ControlRotation.Yaw`
3. `YawRot = Rot(0, Yaw, 0)`
4. `Forward = RotMatrix(YawRot).GetUnitAxis(X)`
5. `Right   = RotMatrix(YawRot).GetUnitAxis(Y)`
6. `AddMovementInput(Forward, Move.Y)`
7. `AddMovementInput(Right, Move.X)`

## Deadzone & Hysteresis
- DeadZoneHigh = 0.10 (|Move| > 0.10 => MovementActive)
- DeadZoneLow  = 0.05 (|Move| < 0.05 => MovementInactive)
- Debounce window: 150 ms for state changes (optional)

This prevents jitter around near-zero inputs, stabilizing transitions between free-look and camera-directed movement.

## Blueprint Implementation Notes
- Character Blueprint:
  - Set the properties above on the Character and CharacterMovement components.
- SpringArm/Camera Blueprint:
  - Set `bUsePawnControlRotation = true`.
- Player Controller / Pawn BP:
  - Bind IA_Move (Triggered). Convert Move Vector2D into camera-space Forward/Right vectors using ControlRotation yaw and `Get Forward Vector` / `Get Right Vector` nodes, then call `Add Movement Input`.
  - Implement deadzone: use `Vector Length` and gates/timers for hysteresis.

## C++ Snippet (Optional)
```cpp
// In your character class
void AYourCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
    // Bind IA_Move via Enhanced Input
}

void AYourCharacter::OnMoveInput(const FInputActionValue& Value)
{
    const FVector2D Move = Value.Get<FVector2D>();
    if (Controller)
    {
        const float Yaw = Controller->GetControlRotation().Yaw;
        const FRotator YawRot(0.f, Yaw, 0.f);
        const FVector Forward = FRotationMatrix(YawRot).GetUnitAxis(EAxis::X);
        const FVector Right   = FRotationMatrix(YawRot).GetUnitAxis(EAxis::Y);
        AddMovementInput(Forward, Move.Y);
        AddMovementInput(Right, Move.X);
    }
}

void AYourCharacter::ApplyRotationSettings()
{
    bUseControllerRotationYaw = false;
    UCharacterMovementComponent* MoveComp = GetCharacterMovement();
    if (MoveComp)
    {
        MoveComp->bOrientRotationToMovement = true;
        MoveComp->bUseControllerDesiredRotation = false;
        MoveComp->RotationRate = FRotator(0.f, 720.f, 0.f);
    }
}
```

## AnimBP Coordination (with UJMAnimInstance)
- Call order: `UpdateRotationData -> UpdateVelocityData -> UpdateAccelerationData -> UpdateCharacterStateData -> UpdateJumpFallData -> UpdateBlendWeightData -> UpdateRootYawOffset`
- When Speed > threshold (e.g., 10 cm/s) or Acceleration > small threshold:
  - Reduce TIP (Turn In Place) and `RootYawOffset` influence toward 0 to avoid double-driving yaw while movement already rotates the character.
- When Speed == 0:
  - Allow TIP and RootYawOffset to function normally for idle adjustments.
- Property Access:
  - Use existing variables such as `UpperbodyDynamicAdditiveWeight` and `RootYawOffsetDeg` to blend based on speed/movement state.

## Error Prevention
- Never enable `bOrientRotationToMovement` and `bUseControllerDesiredRotation` simultaneously; OrientRotationToMovement overrides DesiredRotation and may cause unexpected behavior if both are true.
- Always clear `bUseControllerRotationYaw` on the Character to allow free-look when idle.
- Implement input deadzone and hysteresis to avoid frequent state toggles.
- Keep rotation rate in a comfortable range (540鈥?20 deg/s) to balance responsiveness and smoothness.

## Performance Considerations
- CPU cost is minimal (~0.02ms/frame). No extra memory allocations.
- Logging should be disabled in shipping; use debug toggles only.

## Debugging Checklist
- Idle: camera rotates freely, character yaw remains stable.
- Movement: character turns smoothly toward camera-space movement direction.
- Transitions: no jitter when starting/stopping movement; TIP/RootYawOffset disabled while moving, enabled when idle.

## Parameters (Recommended Defaults)
- DeadZoneHigh = 0.10
- DeadZoneLow  = 0.05
- DebounceWindow = 150 ms
- RotationRate.Yaw = 720 deg/s
- SpeedThresholdForTIPOff = 10 cm/s

## Changelog
- v1.0 (UE5.7): Initial guide for Scheme 1 camera-directed movement, single-player only.

## Project-Specific Notes (LyraStarterGame)
- Default toggle: `bCameraDirectedMovementEnabled = true` (C++)
- Fallback when disabled: Actor-space movement (basis = `GetActorRotation().Yaw`), not controller yaw.
- Asset assignment (Blueprint only for pointing assets):
  - `BP_JM_PlayerPawn` 鈫?set `IA_Move_RPG` to `/RPGCore/ProjectJIANMU/Input/IA/IA_Move_RPG`
  - `BP_JM_Pawn` 鈫?set `IMC_JM_Pawn` to `/RPGCore/ProjectJIANMU/Input/IMC/IMC_JM_Pawn`
  - No runtime Blueprint buttons or hotkeys are required.
- Implementation strictly in C++, consistent with Lyra framework patterns.

## Verification
- Camera-directed ON: move input follows camera yaw; smooth rotation via `bOrientRotationToMovement`.
- Camera-directed OFF: move input follows actor yaw; camera free-look unaffected.
- Possession lifecycle: IMC added in `PossessedBy`, removed in `UnPossessed`.
