# Cardinal Anim Set Guide (UE5.7 Single-Player)

## Overview
This guide describes how to use the `FJMCardinalAnimSet` (BlueprintType) to map four cardinal directions to animation sequences: Forward, Backward, Left, Right. It is designed for UE5.7 single-player projects, aligns with Enhanced Input and camera-directed movement, and does not include any networking or RPC features.

## Data Structure
- File: `Source/LyraGame/Animation/JMCardinalAnimSet.h`
- Type: `USTRUCT(BlueprintType)`
- Members: `ForwardAnim`, `BackwardAnim`, `LeftAnim`, `RightAnim` as `UPROPERTY(EditAnywhere, BlueprintReadWrite)` of type `TObjectPtr<UAnimSequenceBase>`
- Utility: `HasAnyAnim()` for safe checks

## Usage Patterns
1) Anim Blueprint (ABP) Variable
- Add a variable of type `FJMCardinalAnimSet` in your ABP (e.g., `ABP_JM_*`).
- Assign sequences in the details panel.
- Use your existing `EJMCardinalDirection` (e.g., `CurrentCardinalDirection`) to select which sequence to play.

2) Selection Logic in AnimGraph
- Implement a Switch by `EJMCardinalDirection` and choose from `ForwardAnim/BackwardAnim/LeftAnim/RightAnim`.
- Drive a `Sequence Player` or a state with the selected sequence.
- Provide fallback when a sequence is missing (e.g., default to `ForwardAnim` or Idle).

3) Alignment with Camera-Directed Movement
- Use `ViewYawDeg` (read-only cache) and your direction selection (e.g., `SelectCardinalDirectionFromAngle`) to unify reference frames.
- Ensure movement dead zone and direction hysteresis are consistent to avoid flickering between directions.

## Compilation & Dependencies
- Include: `Animation/AnimSequenceBase.h`, minimal include hygiene.
- Module: `LyraGame` depends on Engine/CoreUObject (already present).
- No new module dependencies.

## Performance Notes (Single-Player)
- Hard references: The four sequences may be loaded earlier; keep assets modest in size.
- If you later need deferred loading, migrate to soft references (`TSoftObjectPtr<UAnimSequenceBase>`).
- Avoid loading assets during animation tick; pre-assign at initialization.

## Error Prevention Checklist
- Ensure `FJMCardinalAnimSet` properties are assigned (non-null) before play.
- Use `UAnimSequenceBase` only; do not mix up with montages in sequence players.
- Add fallback logic when any direction is unset.
- Keep category and property names consistent: `Cardinal Anim`.
- No networking specifiers; no RPC usage.

## Testing (PIE)
- Move Forward/Backward/Left/Right and watch direction changes.
- Log `CurrentCardinalDirection` and confirm sequence switches are correct.
- Use `ShowDebug Animation` and `Stat Anim` to verify transitions.
- Validate with camera-directed toggles to ensure `ViewYawDeg` alignment.

## Blueprint-Friendly Tips
- Mark variables as `EditAnywhere, BlueprintReadWrite` for ABP configuration.
- Consider a small Blueprint function to select sequence by direction to reduce graph duplication.

## Maintenance
- Keep the struct small and focused; avoid coupling with AnimInstance headers.
- Document any new fallback or selection policies in project standards.

## Compliance
- UE5.7 toolchain only.
- Single-player only; no networking.
- English filename in `Documentation/CodeGuidelines`.
