# Animation_UpdateRotationData_Guide

涓枃/English mixed guide to implement and use UpdateRotationData in UJMAnimInstance for UE5.7 single-player projects.

## 姒傝堪 / Overview
- 鐩爣锛氬湪 AnimBP 鐨?鈥淏lueprint Thread Safe Update Functions鈥?闃舵锛屼娇鐢?C++ 鍑芥暟 `UpdateRotationData` 杩涜鍙閲囨牱涓庤交閲忚绠椼€?- 鐗瑰寲锛氶伒寰崟鏈烘父鎴忛檺鍒讹紙No networking/No RPC锛夛紝浠呬娇鐢ㄦ湰鍦版暟鎹笌绠€鍖栭€昏緫锛岄伩鍏嶆€ц兘璐熸媴銆?- 鍏煎锛氬彉閲忓垎绫讳笌鍚嶇О鍙洿鎺ュ湪钃濆浘涓闂紝Blueprint 鍙嬪ソ銆?
## 鏂囦欢 / Files
- Source/LyraGame/Animation/JMAnimInstance.h/.cpp
- 鏈寚鍗楋細Documentation/CodeGuidelines/Animation_UpdateRotationData_Guide.md

## 鍙橀噺鍒嗙被 / Variable Categories
### Rotation Data
- `ActorYaw`锛氬綋鍓嶄笘鐣屾棆杞殑 Yaw锛堝害锛?- `PreviousActorYaw`锛氫笂涓€甯?Yaw锛堝害锛?- `DeltaYawSinceLastUpdate`锛氬綋鍓嶄笌涓婁竴甯у樊鍊硷紝鑼冨洿 [-180, 180]
- `YawSpeedDegPerSec`锛氭棆杞€熷害锛堝害/绉掞級

### Settings锛堟棆杞浉鍏筹級
- `IsFirstRotationUpdate`锛氶甯у拷鐣ユ棆杞樊涓庨€熷害
- `TurnInPlaceMoveSpeedThreshold`锛氬綋浣嶇Щ閫熷害浣庝簬闃堝€兼椂鍙備笌鍘熷湴杞韩绱锛坈m/s锛?- `YawSpeedSmoothingAlpha`锛氭棆杞€熷害骞虫粦绯绘暟锛堝彲閫変娇鐢級

### Turn In Place
- `bEnableTurnInPlace`锛氭槸鍚﹀惎鐢ㄥ師鍦拌浆韬垽瀹?- `TurnInPlaceTriggerAngleDeg`锛氱疮璁¤揪鍒拌瑙掑害瑙﹀彂 TIP锛堝害锛?- `AccumulatedYawForTIP`锛氱疮璁＄殑鍘熷湴鏃嬭浆瑙掑害锛堟鍙宠礋宸︼紝搴︼級
- `bTurnInPlaceTriggered`锛氭湰甯ф槸鍚﹁Е鍙?TIP
- `TurnInPlaceDirectionSign`锛歍IP 瑙﹀彂鏂瑰悜锛? 鍙宠浆锛?1 宸﹁浆锛? 鏈Е鍙戯級

## 钃濆浘闆嗘垚姝ラ / AnimBP Integration Steps
1. 鍦?AnimBP 涓皢鐖剁被璁剧疆涓?`UJMAnimInstance`銆?2. 鎵撳紑 鈥淏lueprint Thread Safe Update Animation鈥?浜嬩欢鍥撅細
   - 鍏堣皟鐢?`UpdateLocationData(DeltaTime)`锛堢敤浜?DisplacementSpeed 璁＄畻锛夈€?   - 鍐嶈皟鐢?`UpdateRotationData(DeltaTime)`锛圱IP 鍒ゅ畾渚濊禆浣嶇Щ閫熷害锛夈€?3. 鏄犲皠鍙橀噺鍒板姩鐢诲浘锛?   - 浣跨敤 `YawSpeedDegPerSec` 杩涜閫熷害鐩稿叧鐨勬棆杞钩婊戯紙濡傞渶瑕侊級銆?   - 浣跨敤 `bTurnInPlaceTriggered` 涓?`TurnInPlaceDirectionSign` 椹卞姩杞韩鍔ㄧ敾锛圫tate/Blend/Slot锛夈€?   - `AccumulatedYawForTIP` 鍙敤浜庤嚜瀹氫箟绱鏄剧ず鎴栬緟鍔╅€昏緫銆?
## 鑷娓呭崟 / Self-Check
- UFUNCTION 浣跨敤 `meta=(BlueprintThreadSafe)`锛堝凡璁剧疆锛夈€?- UPROPERTY 鍒嗙被涓庡悕绉扮鍚堣摑鍥句晶灞曠ず闇€姹傦紙鑻辨枃鍛藉悕锛屼腑鏂囨敞閲婏級銆?- 鏃犲閮ㄥ璞′慨鏀癸紱鍑芥暟浣撲粎鍐欏叆鏈被鍙橀噺锛岀嚎绋嬪畨鍏ㄣ€?- 閬垮厤闄ら浂锛歚SafeDeltaTime` 淇濇姢銆?- 绉诲姩鏃堕噸缃?TIP 绱锛涗粎鍦ㄤ綆閫熺Щ鍔ㄦ椂绱骞惰Е鍙戙€?- 涓嶆秹鍙婄綉缁?澶嶅埗/RPC銆?
## 缂栬瘧 / Compile
浣跨敤 UE5.7 鏍囧噯鍛戒护锛圵indows锛夛細

```
& "G:\UE_5.7\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" LyraGame Win64 Development "g:\Project\LyraStarterGame\LyraStarterGame.uproject" -WaitMutex -FromMsBuild
```

## 鎬ц兘涓庨闄?/ Performance & Risks
- 鎬ц兘锛氱函閲囨牱涓庡熀纭€鏁板璁＄畻锛屾瘡甯у紑閿€鏋佷綆锛?< 0.05ms锛屾寜涓€鑸鑹插満鏅及绠楋級銆?- 椋庨櫓锛?  - 棣栧抚鏈垵濮嬪寲瀵艰嚧灏栧嘲锛堝凡閫氳繃 `IsFirstRotationUpdate` 闃叉姢锛夈€?  - 楂橀€熺Щ鍔ㄨЕ鍙?TIP 涓嶅悎鐞嗭紙宸查€氳繃 `TurnInPlaceMoveSpeedThreshold` 鎶戝埗锛夈€?  - 寮傚父 DeltaTime锛堝凡鍋?KINDA_SMALL_NUMBER 闃叉姢锛夈€?
## 鎵╁睍寤鸿 / Extension Suggestions
- 濡傞渶鏇村钩婊戠殑閫熷害鏇茬嚎锛屽彲閫夌敤 `YawSpeedSmoothingAlpha` 鍋?`FMath::Lerp` 鎴?`FMath::ExponentialMovingAverage`銆?- 濡傞渶鏇村鏉?TIP 绛栫暐锛屽彲灏嗙疮璁¤搴︿笌瑙掕壊濮挎€併€佹鍣ㄧ姸鎬佺瓑缁撳悎锛屼絾璇蜂繚鎸佺嚎绋嬪畨鍏ㄤ笌鏈€灏忚绠楀紑閿€銆?
## 鐗堟湰涓庨檺鍒?/ Version & Constraints
- Engine锛歎E 5.6
- 椤圭洰锛氬崟鏈猴紙No Net, No RPC锛?- 鏂囦欢鍛藉悕锛氬叏閮ㄨ嫳鏂?
---
缁存姢浜?/ Maintainer: Animation Team
鏇存柊鏃堕棿 / Last Update: 鑷姩鍒涘缓浜庡疄鐜伴樁娈
