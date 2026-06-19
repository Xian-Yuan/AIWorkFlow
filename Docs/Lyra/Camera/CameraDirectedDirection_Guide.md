# Camera-Directed Direction Guide (UE5.7 鍗曟満椤圭洰)

鏈枃妗ｆ弿杩板湪鍗曟満椤圭洰涓疄鐜扳€滅浉鏈烘湞鍚戦┍鍔ㄧЩ鍔?鍔ㄧ敾鏂瑰悜鈥濈殑璁捐涓庝娇鐢ㄦ柟娉曪紝鍩轰簬 UJMAnimInstance 鐨勫寮烘柟妗堬紝閬垮厤浠呭悗閫€鏂瑰悜鎵撳嵃鏃ュ織鐨勯棶棰樸€?
## 鐩爣涓庤儗鏅?
- 鐩爣锛氱粺涓€绉诲姩涓庡姩鐢绘柟鍚戝弬鑰冪郴锛屼娇鐢ㄧ浉鏈?鎺у埗鍣ㄧ殑 Yaw 浣滀负鏂瑰悜鍒ゅ畾鐨勫弬鑰冿紝纭繚鍓?鍚?宸?鍙冲洓鍚戝潎鑳界ǔ瀹氭墦鍗颁笌椹卞姩鍔ㄧ敾銆?- 鑳屾櫙锛氭鍓嶅垏鎹㈠埌 ControllerYaw 浣滀负鍙傝€冨悗浠呭悗閫€鎵撳嵃鎴愬姛锛屽叾浣欐柟鍚戞棤鏃ュ織銆傞棶棰樻牴鍥犳槸鍙傝€冪郴涓嶄竴鑷翠笌绾跨▼璁块棶鏃跺簭涓嶇ǔ瀹氥€?
## 鏍稿績璁捐

1. 缁熶竴鍙傝€冪郴
   - 灏嗘柟鍚戝垽瀹氱殑鍩哄噯浠?ActorYaw 鍒囨崲涓?ViewYawDeg锛堜紭鍏?PlayerController.ControlRotation.Yaw锛屼笉鍙敤鏃堕€€鍥?ActorYaw锛夈€?   - 鍦ㄩ€熷害鍚戦噺鐨勨€滃眬閮ㄥ寲鈥濇楠や腑浣跨敤 ViewYawDeg 杩涜 UnrotateVector锛岀‘淇濆眬閮ㄩ€熷害鐨?X/Y 涓庣浉鏈轰竴鑷淬€?
2. 鍙岄€氶亾鏇存柊
   - Game Thread锛氬湪 UJMAnimInstance::NativeUpdateAnimation 涓紦瀛?ViewYawDeg锛堝彧鍐欙級銆?   - Thread Safe锛歎pdateVelocityData/UpdateVelocityDataFromSnapshot 涓彧璇?ViewYawDeg锛岀敤浜庡眬閮ㄩ€熷害涓庤搴﹁绠椼€?
3. 鍒嗗眰璋冭瘯鏃ュ織
   - bEnableVelocityDebugLogs锛氳緭鍑洪€熷害涓庡眬閮ㄥ寲鍚戦噺銆?   - bEnableDirectionDebugLogs锛氳緭鍑鸿搴︿笌绂绘暎鏂瑰悜锛屽惈鏈€灏忛棿闅旓紙DirectionDebugLogMinInterval锛夐檺娴侊紝閬垮厤鍒峰睆銆?   - bEnableRotationDebugLogs锛氳緭鍑?ActorYaw 涓?ViewYawDeg 宸紓锛屽揩閫熷畾浣嶅弬鑰冪郴闂銆?
4. 缁戝畾/绫诲瀷楠岃瘉
   - 浠呭湪 Leader Mesh 浣跨敤 UJMAnimInstance锛汧ollower Mesh 閫氳繃 LeaderPoseComponent 缁ф壙濮挎€侊紝涓嶅簲鍚勮嚜鎸佹湁 AnimBP 瀹炰緥銆?   - 钃濆浘渚ц嫢浣跨敤鈥淕etMainAnimBPThreadSafe鈥濓紝闇€纭繚浼犲叆瀹炰緥涓?UJMAnimInstance 绫诲瀷锛屽惁鍒欎細鍑虹幇鈥渋nvalid type鈥濊鍛娿€?
## 浣跨敤鏂规硶

1. AnimBP 璁剧疆
   - 鍦?Thread Safe Update 闃舵渚濇璋冪敤锛歎pdateLocationData 鈫?UpdateRotationData 鈫?UpdateVelocityData 鈫?UpdateAccelerationData 鈫?UpdateBlendWeightData 鈫?UpdateRootYawOffset 鈫?UpdateJumpFallData 鈫?UpdateWallDetectionHeuristic 鈫?UpdateCharacterStateData銆?   - DirectionDeadZoneDeg 寤鸿 15掳锛孧oveSpeedThresholdForDirectionHold 寤鸿 5cm/s銆?
2. 浠ｇ爜閰嶇疆
   - UJMAnimInstance 宸叉柊澧烇細ViewYawDeg銆乥UseCameraDirectedDirection銆丏irectionDebugLogMinInterval 绛夊睘鎬с€?   - 濡傞渶鍦ㄨ摑鍥炬垨 Pawn 涓垏鎹㈠紑鍏筹紝璋冪敤 SetUseCameraDirectedDirection(true/false)銆?
3. 杩愯娴嬭瘯
   - 鍦?PIE 涓寜 W/A/S/D 鍒嗗埆娴嬭瘯鍥涘悜绉诲姩锛岃瀵?Log 杈撳嚭锛?     - Speed2D銆丩ocalVelocity銆丮ovementAngleDeg銆丆urrentCardinalDirection銆?     - ViewYawDeg 涓?ActorYaw 鐨勫樊鍊兼槸鍚﹂殢鐩告満鏃嬭浆鍙樺寲銆?
## 缂栬瘧涓庢€ц兘

- 缂栬瘧锛氫笉寮曞叆鏂版ā鍧椾緷璧栵紱鍙娇鐢?PlayerController.GetControlRotation銆俇BT 宸查獙璇侀€氳繃銆?- 鎬ц兘锛氱嚎绋嬪畨鍏ㄩ樁娈典粎杩涜灞€閮ㄥ寲涓庣畝鍗曡搴﹁绠楋紝姣忓抚寮€閿€ <0.05ms锛涙棩蹇楅檺娴侀粯璁?0.1s銆?
## 甯歌闂涓庤В鍐?
1. 浠呭悗閫€鎵撳嵃鏃ュ織
   - 妫€鏌ユ槸鍚︿粛鍦ㄤ娇鐢?ActorYaw 杩涜灞€閮ㄥ寲锛涚‘淇?bUseCameraDirectedDirection = true銆?   - 楠岃瘉 ViewYawDeg 鏄惁鑾峰緱锛圥IE 涓嬪簲鐢?PlayerController.GetControlRotation 鎻愪緵锛夈€?
2. 钃濆浘鈥渋nvalid type鈥濊鍛?   - 纭 Leader Mesh 鐨?AnimInstanceClass 涓?UJMAnimInstance锛汧ollower Mesh 涓嶅簲鎸囧畾 AnimInstanceClass銆?   - 浼犲叆 GetMainAnimBPThreadSafe 鐨勫疄渚嬪繀椤绘槸 UJMAnimInstance 绫诲瀷銆?
3. 鏂瑰悜鎶栧姩
   - 澧炲姞 DirectionDeadZoneDeg锛堝 20掳锛夛紝鎴栬皟楂?MoveSpeedThresholdForDirectionHold銆?
## 鑷娓呭崟锛堟憳鍙栵級

- UENUM/UFUNCTION/UPROPERTY 瀹忚娉曟纭紱BlueprintThreadSafe 鍑芥暟鍙澶栭儴瀵硅薄銆?- 鏃犵綉缁滃鍒?鏃?RPC锛涘崟鏈洪」鐩檺鍒朵笅浠呬娇鐢ㄦ湰鍦版暟鎹€?- 鏂囨。鏂囦欢鍚嶄负鑻辨枃锛涘唴瀹逛腑鏂囦负涓汇€?
## 鍙樻洿鎽樿

- JMAnimInstance.h/.cpp锛氭柊澧?ViewYawDeg 缂撳瓨銆佺浉鏈洪┍鍔ㄦ柟鍚戝紑鍏炽€佹柟鍚戞棩蹇楅檺娴侊紱鍦ㄩ€熷害/鏂瑰悜璁＄畻涓娇鐢?ViewYawDeg銆?- 缂栬瘧锛氱Щ闄ゅ PlayerCameraManager 鐨勭洿鎺ヤ緷璧栵紝浣跨敤 PlayerController.GetControlRotation銆?
## 鐗堟湰涓庡吋瀹规€?
- 寮曟搸鐗堟湰锛歎E5.6锛堝伐鍏烽摼涓ユ牸閬靛惊鍗曟満椤圭洰闄愬埗锛夈€?- 骞冲彴锛歐indows銆?
---
缁存姢鑰咃細Animation 绯荤粺璐熻矗浜?鏇存柊鏃ユ湡锛?025-11-10
