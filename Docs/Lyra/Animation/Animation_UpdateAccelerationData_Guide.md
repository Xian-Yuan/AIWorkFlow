# Animation UpdateAccelerationData Guide (UE5.7, Single-Player)

涓枃璇存槑鍦ㄤ笂锛岃嫳鏂囪鏄庡湪涓嬶紱鏂囦欢鍚嶄娇鐢ㄨ嫳鏂囦互绗﹀悎椤圭洰瑙勮寖銆?
## 鐩殑
- 涓?AnimBlueprint 鎻愪緵绾跨▼瀹夊叏鐨勫姞閫熷害閲囨牱涓?Pivot 鏂瑰悜閫夋嫨锛岄┍鍔ㄦ€ュ仠/杞韩绛夊姩鐢汇€?- 淇濇寔涓庡凡瀹炵幇鐨勯€熷害/鏂瑰悜閫昏緫涓€鑷达細閫熷害椹卞姩褰撳墠鏂瑰悜銆佸姞閫熷害琛ㄨ揪鐜╁鎰忓浘鐢ㄤ簬 Pivot銆?
## 绫诲瀷涓庡嚱鏁?- UENUM: EJMCardinalDirection锛團orward/Right/Backward/Left锛夈€?- UCLASS: UJMAnimInstance锛堢户鎵?ULyraAnimInstance锛夈€?- UFUNCTION:
  - UpdateAccelerationData(float DeltaTime): 绾跨▼瀹夊叏閲囨牱涓庤绠楀姞閫熷害鍜?Pivot 鏂瑰悜銆?  - GetOppositeCardinalDirection(EJMCardinalDirection): 杩斿洖鐩稿弽鏂瑰悜銆?  - 澶嶇敤 SelectCardinalDirectionFromAngle(angle, prev, deadZone)銆?
## 鍏抽敭鍙橀噺锛圲PROPERTY锛?- Acceleration Data锛堝彧璇伙級
  - WorldAcceleration2D: XY 骞抽潰涓栫晫鍔犻€熷害锛涙潵婧?CharacterMovementComponent::GetCurrentAcceleration锛孼=0銆?  - LocalAcceleration2D: 灏嗕笘鐣屽姞閫熷害鎸夎鑹?Yaw 鏃嬪埌灞€閮ㄧ┖闂淬€?  - bHasAcceleration: |LocalAcceleration2D| > AccelerationErrorTolerance銆?  - PivotDirectionFromAcceleration: 鍩轰簬鍔犻€熷害椹卞姩鐨?Pivot 鏂瑰悜銆?- Settings锛堝彲缂栬緫锛?  - AccelerationErrorTolerance = 1.0f锛堝缓璁?0.5~5.0锛夛紱杩囧皬浼氬鑷存姈鍔紝杩囧ぇ澶卞幓鍝嶅簲銆?  - AccelerationDirectionDeadZoneDeg = 15.0f锛堝缓璁?5~20掳锛夛紱鐢ㄤ簬鏂瑰悜閫夋嫨婊炲洖绋冲畾銆?  - bUseCurrentDirectionWhenAccelerating = true锛涙湁鍔犻€熷害鏃剁洿鎺ュ鐢ㄥ綋鍓嶉€熷害鏂瑰悜涓?Pivot銆?  - bUseOppositeWhenNoAcceleration = true锛涙棤鍔犻€熷害鏃朵娇鐢ㄥ綋鍓嶆柟鍚戠殑鐩稿弽鏂瑰悜浣滀负 Pivot銆?  - bEnableAccelDebugLogs = false锛涘紑鍚悗鍦ㄩ闄?寮傚父鐐规墦鍗版棩蹇楋紙UE_LOG锛夈€?
## AnimBP 闆嗘垚寤鸿锛堟寜鍥撅級
1) Blueprint Thread Safe Update Animation 闃舵璋冪敤椤哄簭锛?   - UpdateLocationData -> UpdateRotationData -> UpdateVelocityData -> UpdateAccelerationData銆?2) 閫昏緫鏄犲皠锛?   - World Acceleration 2D锛氳鍙?WorldAcceleration2D銆?   - Local Acceleration 2D锛氳鍙?LocalAcceleration2D銆?   - Has Acceleration锛氳鍙?bHasAcceleration銆?   - Pivot Direction锛氳鍙?PivotDirectionFromAcceleration锛堟垨鏍规嵁璁剧疆鍙?CurrentCardinalDirection/Opposite锛夈€?3) 鐢ㄩ€旓細
   - 灏?PivotDirectionFromAcceleration 椹卞姩鈥淧ivot/鎬ュ仠鈥濈姸鎬佹満鎴栭€夋嫨鑺傜偣锛汣urrentCardinalDirection 缁х画椹卞姩绉诲姩鐘舵€佹満銆?
## 榛樿鍙傛暟涓庤皟鍙傚缓璁?- AccelerationErrorTolerance = 1.0锛氬吀鍨嬬涓変汉绉拌鑹插鍔犻€熻交寰尝鍔ㄤ笉鏁忔劅銆?- AccelerationDirectionDeadZoneDeg = 15.0锛氫笌閫熷害鏂瑰悜姝诲尯涓€鑷达紝淇濇寔绋冲畾鎬с€?- MoveSpeedThresholdForDirectionHold = 5.0锛氶€熷害鏂瑰悜鐨勪綆閫熶繚鎸侀槇鍊间笉鍙樸€?- bUseCurrentDirectionWhenAccelerating = true锛氭洿绗﹀悎鐜╁浣撻獙锛孭ivot 涓庡綋鍓嶇Щ鍔ㄦ柟鍚戜竴鑷淬€?- bUseOppositeWhenNoAcceleration = true锛氭棤鍔犻€熷害锛堟剰鍥惧仠姝㈡垨鍙嶅悜锛夋椂缁欏嚭绋冲仴鐨勭浉鍙嶆柟鍚戙€?
## 閿欒棰勯槻涓庢棩蹇?- MovementComponent 涓嶅彲鐢細鍒ゅ畾鏃犲姞閫熷害骞舵寜璁剧疆閫夋嫨 Pivot锛涘寮€鍚?bEnableAccelDebugLogs 鍒?Warning銆?- 闈?CharacterMovementComponent锛氭棤娉曡幏鍙栧綋鍓嶅姞閫熷害锛岃蛋鏃犲姞閫熷害瀹归敊璺緞锛涘紑鍚棩蹇楁椂 Warning銆?- Angle 闈炴湁闄愶紙NaN/Inf锛夛細鍥為€€鍒?CurrentCardinalDirection锛屽紑鍚棩蹇楁椂 Warning銆?- DeadZone 瓒呯晫锛氳嚜鍔ㄥす鍙栧埌 [0,45]锛屽紑鍚棩蹇楁椂 Warning銆?- 鏃犲姞閫熷害鍒嗘敮锛氭寜璁剧疆浣跨敤 Opposite 鎴?Current锛涘紑鍚棩蹇楁椂鎵撳嵃 Log銆?
## 鎬ц兘涓庣紪璇?- 杩愯鏃讹細O(1)锛屾瘡甯х害 <0.02ms锛涗粎鏈湴璁＄畻锛屾棤棰濆鍐呭瓨涓?I/O銆?- 缂栬瘧锛氬 LyraGame 鐩爣鏃犳柊澧炰緷璧栵紱閬靛惊 UHT 瑙勫垯锛圲ENUM 鍏ㄥ眬浣滅敤鍩燂級銆?
## 璋冭瘯鎶€宸?- 鍦?PIE 涓嬪垏鎹?bEnableAccelDebugLogs锛岃瀵熸棩蹇椾腑 Pivot 閫夋嫨鍒嗘敮涓庤搴︺€佸宸€佹鍖哄す鍙栨儏鍐点€?- 鍒╃敤 DrawDebug 瑙傚療 LocalAcceleration2D 鏂瑰悜锛堝彲鍦ㄨ摑鍥句腑瀹炵幇锛屼笉寤鸿鍦?C++ 涓父鎬佺粯鍒讹級銆?
---

# Animation UpdateAccelerationData Guide (English)

Purpose:
- Provide thread-safe acceleration sampling and Pivot direction selection for AnimBlueprint.
- Keep consistent with existing velocity-driven direction: velocity drives CurrentCardinalDirection; acceleration expresses player intent for Pivot.

Functions and Types:
- EJMCardinalDirection (Forward/Right/Backward/Left) at global scope.
- UJMAnimInstance extends ULyraAnimInstance.
- UpdateAccelerationData(float), GetOppositeCardinalDirection(EJMCardinalDirection), and reuse SelectCardinalDirectionFromAngle.

Key UPROPERTY:
- WorldAcceleration2D (XY, from CharacterMovementComponent::GetCurrentAcceleration, Z=0), LocalAcceleration2D, bHasAcceleration, PivotDirectionFromAcceleration.
- Settings: AccelerationErrorTolerance, AccelerationDirectionDeadZoneDeg, bUseCurrentDirectionWhenAccelerating, bUseOppositeWhenNoAcceleration, bEnableAccelDebugLogs.

AnimBP wiring:
- Call order: UpdateLocationData -> UpdateRotationData -> UpdateVelocityData -> UpdateAccelerationData.
- Read data and drive Pivot/stop/turn animations with PivotDirectionFromAcceleration; continue using CurrentCardinalDirection for locomotion.

Error prevention and logs:
- Missing MovementComponent / Non-Character movement: treat as no acceleration; log warnings when bEnableAccelDebugLogs.
- Non-finite angle: fallback to CurrentCardinalDirection; warn when bEnableAccelDebugLogs.
- Dead zone clamped to [0,45]; warn when clamping.

Performance & Compilation:
- O(1) runtime; minimal CPU cost; no new dependencies; adheres to UE5.7 UHT rules.

Notes:
- Logging is gated by bEnableAccelDebugLogs to avoid spam; only risky/exception cases emit warnings; normal branch emits logs at Log level.
