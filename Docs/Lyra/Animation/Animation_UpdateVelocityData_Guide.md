# Animation Velocity & Cardinal Direction Guide (UE5.7 Single-Player)

This guide documents the implementation and usage of UpdateVelocityData and SelectCardinalDirectionFromAngle in UJMAnimInstance for UE5.7 single-player projects.

Language: 涓枃涓轰富锛岄檮鑻辨枃鏈璇存槑銆?
## 姒傝堪 Overview

- 鐩爣锛氬湪 AnimBlueprint 鐨勭嚎绋嬪畨鍏ㄦ洿鏂伴樁娈碉紙Blueprint Thread Safe Update Animation锛夐噰鏍疯鑹查€熷害锛屽苟杈撳嚭鍥涘悜绂绘暎鏂瑰悜锛團orward/Right/Backward/Left锛夛紝鐢ㄤ簬椹卞姩绉诲姩鍔ㄧ敾鐨勭ǔ瀹氭贩鍚堛€?- 鐗规€э細
  - 瑙掑害褰掍竴鍖栵紙Normalize angle to [-180, 180]锛夈€?  - 姝诲尯涓庢粸鍥烇紙Dead Zone & Hysteresis锛夐伩鍏嶈竟鐣屾姈鍔ㄣ€?  - 浣庨€熶繚鎸佷笂涓€鏂瑰悜锛圠ow speed hold previous direction锛夈€?  - 瀹屽叏鏈湴锛屾嫆缁濅换浣曠綉缁滃鍒?RPC銆?  - 瀹屾暣 Blueprint 鍏煎锛屼腑鏂囨敞閲娿€?
## 鏂板/浣跨敤鐨勭被鍨?Types

- 鍏ㄥ眬鏋氫妇 UENUM(BlueprintType) enum class EJMCardinalDirection : uint8 { Forward, Right, Backward, Left }銆?
## 鍏抽敭鍑芥暟 Functions

- BlueprintPure, BlueprintThreadSafe:
  - EJMCardinalDirection SelectCardinalDirectionFromAngle(float AngleDeg, EJMCardinalDirection PrevDir, float DeadZoneDeg) const
    - 杈撳叆 AngleDeg锛氱浉瀵瑰墠鍚戣搴︼紙搴︼紝寤鸿 [-180, 180]锛夈€?    - 杈撳叆 PrevDir锛氫笂涓€甯ф柟鍚戙€?    - 杈撳叆 DeadZoneDeg锛氭鍖鸿搴︼紙榛樿 15掳锛夛紝缂╃獎绋冲畾鑼冨洿閬垮厤鎶栧姩銆?    - 杈撳嚭锛氭柊鐨勫洓鍚戞柟鍚戙€?
- BlueprintCallable, BlueprintThreadSafe:
  - void UpdateVelocityData(float DeltaTime)
    - 閲囨牱 WorldVelocity锛堝彲蹇界暐 Z锛夛紝璁＄畻 LocalVelocity锛堟牴鎹綋鍓?Yaw锛夛紝寰楀埌 Speed2D 涓?MovementAngleDeg锛屽苟閫氳繃 SelectCardinalDirectionFromAngle 杈撳嚭 CurrentCardinalDirection銆?    - 浣庨€熼槇鍊硷紙MoveSpeedThresholdForDirectionHold锛変笅淇濇寔涓婁竴鏂瑰悜锛岄伩鍏嶅仠璧拌竟缂樻姈鍔ㄣ€?
## 鍏抽敭鍙橀噺 Variables锛圕ategory锛?
- Velocity Data锛?  - WorldVelocity锛堜笘鐣岄€熷害锛屽拷鐣?Z 鍙€夛級銆?  - LocalVelocity锛堢浉瀵瑰綋鍓嶆湞鍚戠殑灞€閮ㄩ€熷害锛夈€?  - Speed2D锛堝钩闈㈤€熷害 cm/s锛夈€?  - MovementAngleDeg锛堝眬閮ㄧЩ鍔ㄨ搴︼紝搴︼級銆?
- Direction锛?  - CurrentCardinalDirection锛堝綋鍓嶅洓鍚戞柟鍚戯級銆?  - PreviousCardinalDirection锛堜笂涓€甯у洓鍚戞柟鍚戯級銆?
- Settings锛?  - UseXYOnly锛堝拷鐣?Z锛岄粯璁?true锛夈€?  - DirectionDeadZoneDeg锛堟柟鍚戞鍖鸿锛岄粯璁?15掳锛夈€?  - MoveSpeedThresholdForDirectionHold锛堜綆閫熶繚鎸侀槇鍊硷紝榛樿 5 cm/s锛夈€?
## 闆嗘垚姝ラ Integration Steps

1. AnimBlueprint 鐨?Blueprint Thread Safe Update Animation 闃舵锛氭寜搴忚皟鐢?   - UpdateLocationData(DeltaTime)
   - UpdateRotationData(DeltaTime)
   - UpdateVelocityData(DeltaTime)

2. 浣跨敤 CurrentCardinalDirection 椹卞姩鍔ㄧ敾锛?   - 鏂规A锛氱姸鎬佹満 4 鐘舵€侊紙Forward/Right/Backward/Left锛夛紝鏍规嵁 CurrentCardinalDirection 杩涘叆瀵瑰簲鐘舵€併€?   - 鏂规B锛欴irection Blend锛堟灇涓?-> 閫夋嫨鑺傜偣锛夛紝灏嗗洓涓柟鍚戠殑 BlendSpace/Sequence 杩涜娣峰悎銆?
3. 鍙€夛細灏?MovementAngleDeg 杈撳嚭鍒拌皟璇?Widget 鎴栨洸绾跨洃鎺э紝楠岃瘉瑙掑害涓庢柟鍚戠殑涓€鑷存€с€?
## 榛樿鍙傛暟鎺ㄨ崘 Defaults

- DirectionDeadZoneDeg = 15掳
- MoveSpeedThresholdForDirectionHold = 5 cm/s
- UseXYOnly = true

## 閿欒棰勯槻涓庤嚜妫€ Error Prevention & Self-check

- UENUM 蹇呴』浣嶄簬鍏ㄥ眬浣滅敤鍩燂紙Global scope锛夈€?- BlueprintThreadSafe 浠呰繘琛屽彧璇婚噰鏍蜂笌绾绠楋紝涓嶄慨鏀瑰閮ㄥ璞℃垨鎵ц鑰楁椂鎿嶄綔銆?- Angle 缁熶竴褰掍竴鍖栧埌 [-180, 180]锛岄伩鍏嶈竟鐣屼笉涓€鑷淬€?- FindDeltaAngleDegrees 鐢ㄤ簬鏈€灏忚宸绠楋紝淇濊瘉 卤180 涓€鑷存€с€?- KINDA_SMALL_NUMBER 淇濇姢 DeltaTime 涓庨槇鍊煎垽鏂紝閬垮厤闄ら浂涓庢诞鐐瑰櫔澹般€?- 閫熷害闃堝€间笅淇濇寔涓婁竴鏂瑰悜锛岄伩鍏嶅仠璧版姈鍔ㄣ€?
## 鎬ц兘涓庣紪璇?Performance & Build

- 杩愯鏃跺鏉傚害 O(1)锛岄璁?<0.02ms/甯э紙妗岄潰 CPU锛夈€?- 鍐呭瓨寮€閿€鏋佸皬锛屼粎灏戦噺 float 涓庢灇涓惧彉閲忋€?- UE5.7 宸ュ叿閾惧閲忕紪璇戝紑閿€鏋佷綆锛涘畬鏁寸紪璇戞棤鏄庢樉褰卞搷銆?
## 璋冭瘯寤鸿 Debugging Tips

- 鍦?AnimBP 涓樉绀?CurrentCardinalDirection锛圗num -> String锛夊拰 MovementAngleDeg銆?- 浣庨€熷仠璧版椂妫€鏌ユ槸鍚︿繚鎸佷笂涓€鏂瑰悜锛岄伩鍏嶆柟鍚戞姈鍔ㄣ€?- 璋冩暣 DirectionDeadZoneDeg 涓?MoveSpeedThresholdForDirectionHold锛屾壘鍒伴」鐩渶浼樼偣銆?
## 绾︽潫 Constraints

- 鍗曟満椤圭洰锛氫弗绂佺綉缁滃鍒?Replicate 涓?RPC銆?- 涓嶄慨鏀瑰紩鎿庝唬鐮侊紝涓嶅紩鍏ラ澶栨ā鍧椾緷璧栥€?- 鏂囦欢鍚嶄笌璺緞蹇呴』鑻辨枃锛岄伒寰」鐩?Documentation/CodeGuidelines 绾﹀畾銆?
## 鍙樻洿璁板綍 Changelog

- Initial version: Added documentation for velocity sampling and 4-way cardinal direction selection with dead zone & hysteresis for UE5.7.
