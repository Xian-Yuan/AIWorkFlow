# Camera Parameter Conventions (Lyra UE5.7 Single-Player)

鏈枃浠跺畾涔夌帺瀹?PawnData 鐨勭浉鏈哄弬鏁板垎绫讳笌榛樿绾﹀畾锛岀粺涓€绗笁浜虹О涓庢浜や刊瑙嗕袱绉嶆ā寮忕殑鍙厤缃」涓庤鍙栨柟寮忥紝纭繚 Blueprint 鍙嬪ソ銆佸崟鏈烘€ц兘浼樺寲涓庣紪璇戠ǔ瀹氥€?
## 鍒嗙被涓庡懡鍚?
- 绗笁浜虹О鍙傛暟鍒嗙被锛歚Category = "Camera|ThirdPerson"`
- 姝ｄ氦淇鍙傛暟鍒嗙被锛歚Category = "Camera|Ortho"`

淇濇寔涓庨」鐩凡鏈夊瓧娈靛懡鍚嶄竴鑷达紝閬垮厤閲嶅閫犺疆瀛愩€傛墍鏈夊瓧娈典綅浜庯細
- `Source/LyraGame/Character/LyraPawnData.h`

## 绗笁浜虹О鍙傛暟锛堝凡瀛樺湪锛屼繚鎸佷笉鍙橈紝浠呴噸鍒嗙被锛?
- `CameraZoomMinDistance`锛堥粯璁?200.0f锛夛細鏈€杩戣窛绂伙紙杩戞櫙锛?- `CameraZoomMaxDistance`锛堥粯璁?800.0f锛夛細鏈€杩滆窛绂伙紙杩滄櫙锛?- `CameraZoomTweenDuration`锛堥粯璁?1.0f锛夛細缂╂斁缂撳姩鏃堕暱锛堢锛?- `CameraZoomTweenEaseExponent`锛堥粯璁?4.0f锛夛細缂撳姩鏇茬嚎鎸囨暟锛圗aseOut锛?- `CameraZoomSpeedScalar`锛堥粯璁?0.05f锛夛細婊氳疆缂╂斁鐏垫晱搴︼紙姣忔澧為噺锛?- `bCameraZoomInvert`锛堥粯璁?false锛夛細婊氳疆鏂瑰悜鍙嶈浆

璇诲彇浣嶇疆涓庢槧灏勶細
- `LyraPlayerCameraManager` 鏆撮湶 `ZoomTargetScalar(0..1)` 渚涙ā寮忚鍙栥€?- `LyraCameraMode_ThirdPerson.cpp` 灏?`ZoomTargetScalar` 鏄犲皠鍒?`[CameraZoomMinDistance, CameraZoomMaxDistance]` 骞舵寜 `TweenDuration/EaseExponent` 骞虫粦杩囨浮銆?
## 姝ｄ氦淇鍙傛暟锛堟柊澧烇級

- `CameraOrthoMinWidth`锛堥粯璁?4000.0f锛夛細OrthoWidth 鏈€灏忓€硷紙杩戠锛?- `CameraOrthoMaxWidth`锛堥粯璁?12000.0f锛夛細OrthoWidth 鏈€澶у€硷紙杩滅锛?- `CameraOrthoTweenDuration`锛堥粯璁?0.25f锛夛細缂╂斁缂撳姩鏃堕暱锛堢锛?- `CameraOrthoTweenEaseExponent`锛堥粯璁?2.0f锛夛細缂撳姩鏇茬嚎鎸囨暟锛圗aseOut锛?- `CameraOrthoDeadZone`锛堥粯璁?0.05f锛夛細鐩爣姝诲尯锛堟姂鍒舵姈鍔級
- `CameraOrthoFollowDistance`锛堥粯璁?1000.0f cm锛夛細娌垮墠鍚戠殑鍙栨櫙璺濈锛堜笉褰卞搷 OrthoWidth 缂╂斁锛屼粎鐢ㄤ簬鏋勫浘锛?- `CameraOrthoPitchDegrees`锛堥粯璁?-45.0f锛夛細淇瑙掑害锛堝害锛岃礋鍊艰〃绀轰粠涓婂線涓嬬湅锛?
璇诲彇浣嶇疆涓庢槧灏勶細
- `LyraCameraMode_TopDownOrtho.*` 鍦ㄦ縺娲绘椂缂撳瓨 PawnData 鍙傛暟涓?`Effective*`锛屽苟浣跨敤 `LyraPlayerCameraManager::GetZoomTargetScalar()` 灏嗘爣閲忔槧灏勫埌 `[CameraOrthoMinWidth, CameraOrthoMaxWidth]`銆?- 浣嶇疆閲囩敤 `PivotLocation - Forward * CameraOrthoFollowDistance` 瀹炵幇鈥滀粎鏋勫浘鈥濈殑鍙栨櫙鍋忕Щ锛涚缉鏀句笌鎶曞奖涓虹函 OrthoWidth 鎺у埗銆?
## 瑕嗙洊浼樺厛绾э紙鏁版嵁椹卞姩锛?
1. PawnData 瀛楁锛?0 鎴栨湁鏁堝€硷級浼樺厛瑕嗙洊 CameraMode 绫婚粯璁ゅ€笺€?2. 鑻?PawnData 鏈缃紙<=0 鎴栨湭閰嶇疆锛夛紝浣跨敤 CameraMode 鍐呴儴榛樿鍊笺€?3. `ZoomTargetScalar` 濮嬬粓鐢?`ALyraPlayerCameraManager` 鎻愪緵锛堟湰鍦板崟鏈哄彉閲忥紝闈炵綉缁滃鍒讹級銆?
## Blueprint 鍙嬪ソ瑙勮寖

- 鎵€鏈夊彲璋冨弬鏁颁负 `EditDefaultsOnly, BlueprintReadOnly`锛屼究浜庡湪 Data Asset 涓厤缃€?- 鍒嗙被浠?`Camera|ThirdPerson` 涓?`Camera|Ortho` 娓呮櫚鍒嗙粍锛屼究浜庤璁″笀鏌ユ壘涓庢壒閲忛厤缃€?- 绂佹寮曞叆缃戠粶澶嶅埗/RPC锛屽崟鏈洪」鐩粎浣跨敤鏈湴鐘舵€佷笌鏁版嵁璧勪骇銆?
## 璐ㄩ噺涓庢€ц兘绾︽潫锛圲E5.6 鍗曟満锛?
- 鍗曟満椤圭洰闄愬埗锛氫弗绂佷娇鐢ㄧ綉缁滃鍒跺姛鑳戒笌 RPC銆?- 缂栬瘧鏁堢巼锛氫娇鐢ㄥ墠鍚戝０鏄庯紝淇濇寔澶存枃浠惰交閲忥紱閬靛惊椤圭洰 `UE5_6_Compile_Guide.md`銆?- 杩愯鏃舵€ц兘锛氱缉鏀剧紦鍔ㄤ娇鐢ㄥ浐瀹氭椂闀夸笌 EaseOut锛屾鍖烘姂鍒堕珮棰戞姈鍔紝CPU/Mem 寮€閿€鍙拷鐣ャ€?
## 鍙傝€冧唬鐮佷綅缃?
- `Source/LyraGame/Character/LyraPawnData.h`
- `Source/LyraGame/Camera/LyraCameraMode_ThirdPerson.cpp`
- `Source/LyraGame/Camera/LyraCameraMode_TopDownOrtho.h/.cpp`
- `Source/LyraGame/Camera/LyraPlayerCameraManager.h`

浠ヤ笂绾﹀畾纭繚涓ょ鐩告満妯″紡鍦ㄦ暟鎹祫浜т腑閲囩敤涓€鑷寸殑鍙傛暟缁撴瀯涓庨粯璁ゅ€硷紝骞跺湪妯″紡婵€娲绘椂鎸夌粺涓€閫昏緫璇诲彇涓庡簲鐢紝渚夸簬缁存姢涓庢墿灞曘€
