# Animation UpdateJumpFallData Guide (UE5.7 Single-Player)

Maintainer / 缁存姢浜? Animation Team

Version: UE5.7

Status: Introduced for UJMAnimInstance, verified by UBT compilation.

## Purpose / 鐩殑
Provide a lightweight, thread-safe C++ function in `UJMAnimInstance` to compute the time to jump apex for driving Jump/Fall blends and apex-related transitions in AnimBP.

鍦?`UJMAnimInstance` 涓彁渚涗竴涓交閲忋€佺嚎绋嬪畨鍏ㄧ殑 C++ 鍑芥暟鐢ㄤ簬璁＄畻鈥滃埌璺宠穬椤剁偣鏃堕棿鈥濓紝鐢ㄤ簬 AnimBP 椹卞姩璺宠穬/涓嬭惤娣峰悎涓?apex 闄勮繎鐨勮繃娓°€?
## Interface / 鎺ュ彛
- UFUNCTION: `void UpdateJumpFallData(float DeltaTime)`
- UPROPERTY: `float TimeToJumpApex` (BlueprintReadOnly)
- UPROPERTY: `float GravityFallbackAbs` (EditAnywhere, BlueprintReadWrite, default 980.0f)
- UPROPERTY: `bool bEnableJumpFallDebugLogs` (EditAnywhere, BlueprintReadWrite)

## Logic Overview / 閫昏緫姒傝堪
1) Read Movement state from `UCharacterMovementComponent` when available.
2) If `IsFalling()` and `Velocity.Z > 0` (ascending): `TimeToJumpApex = Velocity.Z / |GravityZ|`.
3) Else: `TimeToJumpApex = 0`.
4) If `|GravityZ| < KINDA_SMALL_NUMBER`, use `GravityFallbackAbs` for divide safety.

## Thread-Safe Update Call Order / 绾跨▼瀹夊叏璋冪敤椤哄簭
Recommended to call in AnimBP's "Blueprint Thread Safe Update Functions" stage:
- UpdateRotationData 鈫?UpdateVelocityData 鈫?UpdateAccelerationData 鈫?UpdateCharacterStateData 鈫?UpdateJumpFallData 鈫?UpdateBlendWeightData 鈫?UpdateRootYawOffset

## AnimBP Wiring Tips / 鍔ㄧ敾钃濆浘鎺ョ嚎寤鸿
- Use Property Access to read `TimeToJumpApex`.
- Normalize `TimeToJumpApex` to 0..1 via a simple scalar map if your TIP/Blend requires normalized input (e.g., clamp by expected max apex time).
- Use it to:
  - Ease into apex-related additive poses when `TimeToJumpApex` approaches 0.
  - Gate transitions that should only occur during ascending jump segment.

## Parameters / 鍙傛暟寤鸿
- GravityFallbackAbs: 980.0 (cm/s虏) for standard Earth gravity in Unreal units.
- bEnableJumpFallDebugLogs: default false; enable for in-editor verification.

## Error Prevention / 閿欒棰勯槻
- Null checks for Pawn and MovementComponent; early out to `TimeToJumpApex = 0`.
- Divide-by-zero protection using `GravityFallbackAbs` when `|GravityZ|` is too small.
- Avoid expensive math; only a single division per frame when needed.

## Performance / 鎬ц兘
- Expected runtime overhead: ~0.02鈥?.05 ms/frame on desktop.
- No allocations; minimal memory footprint.

## Version Constraints / 鐗堟湰绾︽潫
- Compatible with UE5.7 toolchain.
- Single-player only; no networking/replication/RPC involved.

## Debugging / 璋冭瘯
- Enable `bEnableJumpFallDebugLogs` to log: `Vz`, `GravityAbs`, `IsFalling`, `TimeToApex`.
- Verify ascending phase shows positive `TimeToApex`, apex and descending phases show `0`.

## Maintenance / 缁存姢
- Keep `TimeToJumpApex` public and BlueprintReadOnly for AnimBP consumption.
- Maintain call order consistency with other Update* functions.
