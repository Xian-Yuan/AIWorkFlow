# Animation Wall Detection Heuristic Guide / 鎾炲妫€娴嬪惎鍙戝紡鎸囧崡

Purpose: Guess if the character is running into a wall by checking three conditions: acceleration exists, speed is relatively low, and the angle between acceleration and velocity is large but not completely opposite.

鏈寚鍗楄鏄庡浣曞湪 UJMAnimInstance 涓娇鐢?UpdateWallDetectionHeuristic 浠ユ帹娴嬧€滄挒澧欌€濈姸鎬侊紙bIsRunningIntoWall锛夈€傞€昏緫瀵瑰簲鐢ㄦ埛鎻愪緵鐨勮摑鍥惧浘骞朵繚鎸佺嚎绋嬪畨鍏ㄤ笌鍗曟満椤圭洰浼樺寲鍘熷垯銆?
## Feature Summary / 鐗规€ф杩?- C++ Properties: bIsRunningIntoWall, WallAccelTolerance, WallLowSpeedThreshold, WallDotMin, WallDotMax, bEnableWallDebugLogs
- C++ Functions: UpdateWallDetectionHeuristic(float DeltaTime), GetIsRunningIntoWallHeuristic() const
- Data Sources: LocalAcceleration2D, LocalVelocity, Speed2D (from UpdateAccelerationData / UpdateVelocityData)
- Thread Safety: BlueprintThreadSafe; read-only sampling; no external object mutation.

## Logic / 閫昏緫璇存槑
1) HasAcceleration = |LocalAcceleration2D| > WallAccelTolerance
2) IsLowSpeed      = Speed2D <= WallLowSpeedThreshold
3) DotInRange      = dot(normalize(LocalAcceleration2D), normalize(LocalVelocity)) 鈭?[WallDotMin, WallDotMax]
4) bIsRunningIntoWall = HasAcceleration AND IsLowSpeed AND DotInRange

娉ㄦ剰锛氱偣绉湪 [-1, 1]锛涙暟鍊艰秺鎺ヨ繎 1 琛ㄧず澶硅瓒婂皬锛岃秺鎺ヨ繎 0 琛ㄧず绾?90掳锛涙帴杩?-1 琛ㄧず瀹屽叏鐩稿弽銆傞粯璁ゅ尯闂?[-0.20, 0.30] 浠ｈ〃鈥滄湁鏄庢樉鍋忓樊锛堝ぇ瑙掑害锛変絾闈炲畬鍏ㄧ浉鍙嶁€濄€傚彲鏍规嵁椤圭洰闇€瑕佽皟鏁翠负鏇村亸鍚戜晶婊戯紙鎺ヨ繎 0锛夋垨鏇村亸鍚戝悜鍚庢帹鍔紙鎺ヨ繎 -1锛夌殑鑼冨洿銆?
## Call Order / 璋冪敤椤哄簭寤鸿
鍦?AnimBP 鐨?"Blueprint Thread Safe Update Functions" 闃舵鎸夊簭璋冪敤锛?1. UpdateLocationData
2. UpdateRotationData
3. UpdateVelocityData
4. UpdateAccelerationData
5. UpdateWallDetectionHeuristic

## Blueprint Mapping / 钃濆浘鏄犲皠
- LocalAcceleration2D 鈫?VectorLength 鈫?涓?WallAccelTolerance 姣旇緝锛圚asAcceleration锛?- Speed2D 鈫?涓?WallLowSpeedThreshold 姣旇緝锛圛sLowSpeed锛?- LocalAcceleration2D 涓?LocalVelocity 褰掍竴鍖?鈫?dot 鈫?InRange[WallDotMin..WallDotMax]锛圖otInRange锛?- AND(HasAcceleration, IsLowSpeed, DotInRange) 鈫?bIsRunningIntoWall锛堟垨璋冪敤 GetIsRunningIntoWallHeuristic锛?
## Defaults / 榛樿鍙傛暟
- WallAccelTolerance: 1.0 cm/s^2锛堝缓璁寖鍥?0.5 ~ 5.0锛?- WallLowSpeedThreshold: 30.0 cm/s锛堟牴鎹Щ鍔ㄧ郴缁熻皟鏁达紝寤鸿 10 ~ 80锛?- WallDotMin: -0.20锛堝缓璁寖鍥?-1.0 ~ 0.4锛?- WallDotMax: 0.30锛堝缓璁寖鍥?-0.4 ~ 1.0锛?
璋冨弬寤鸿锛?- 鑻ユ娴嬭繃浜庢晱鎰熸垨缁忓父璇姤锛岀缉绐勫尯闂存垨澧炲姞浣庨€熼槇鍊笺€?- 鑻ユ娴嬩笉鏄撹Е鍙戯紝鎵╁ぇ鍖洪棿鍒版帴杩?0锛堜晶婊戯級鎴栨帴杩?-1锛堝悜鍚庢帹锛夈€?
## Error Prevention / 閿欒棰勯槻
- 褰掍竴鍖栧墠妫€鏌ュ悜閲忓箙搴︼紙KINDA_SMALL_NUMBER锛夛紝閬垮厤闄ら浂銆?- 楠岃瘉鐐圭Н鏈夐檺锛圛sFinite锛夛紝寮傚父鏃朵笉鍙備笌鍒ゅ畾骞舵墦鍗拌鍛娿€?- 鑻?WallDotMin > WallDotMax 鑷姩浜ゆ崲骞惰褰曟棩蹇楋紙寮€鍚?bEnableWallDebugLogs 鏃讹級銆?- 渚濊禆鍓嶅簲纭繚宸茶皟鐢?UpdateVelocityData 涓?UpdateAccelerationData銆?
## Logging / 鏃ュ織
鍚敤 bEnableWallDebugLogs 鍚庯紝鏈嚱鏁板皢鍦ㄥ叧閿闄╃偣涓庣粨鏋滆緭鍑猴細
- 鍙傛暟鍖洪棿寮傚父锛圡in > Max锛夎嚜鍔ㄤ氦鎹㈡彁绀?- 鍚戦噺骞呭害杩囧皬瀵艰嚧鐐圭Н鏃犳晥鐨勮鍛?- 姹囨€绘墦鍗帮細AccelMag銆丼peed2D銆丏ot銆佸尯闂村垽瀹氥€佹渶缁堢粨鏋?
## Performance / 鎬ц兘
- O(1) 杞婚噺璁＄畻锛涘彧璇昏闂凡閲囨牱鍙橀噺锛涙棤鍐呭瓨鍒嗛厤
- 閫傜敤浜庡崟鏈洪」鐩紱閬靛惊鈥滄€ц兘浼樺厛鈥濆師鍒?
## Compilation Impact / 缂栬瘧褰卞搷
- 浠呭ご/婧愭枃浠跺皬骞呮柊澧烇紱缂栬瘧褰卞搷杞诲井
- 瀹屾暣缂栬瘧绾?+鏁板崄姣锛堜緷椤圭洰鑰屽畾锛?
## Debug Tips / 璋冭瘯鎻愮ず
- 鍦ㄥ叧鍗′腑娴嬭瘯锛?  - 鎸佺画鍚戝墠鍔犻€熸挒澧欍€佷綆閫熶晶婊?  - 绐佺劧鍋滀笅骞惰创澧?  - 浣庨€熸帹澧欎笌杞韩
- 瑙傚療 bIsRunningIntoWall 涓庨€熷害/鍔犻€熷害鍙栧€肩殑涓€鑷存€?
## Compliance / 鍚堣
- 鑻辨枃鏂囦欢鍚嶏紱鏂板鏂囨。浣嶄簬 Documentation/CodeGuidelines
- 鍗曟満椤圭洰闄愬埗锛氭湭浣跨敤缃戠粶澶嶅埗/RPC
- UE5.7 宸ュ叿閾惧吋瀹癸紱Blueprint 鍙嬪ソ锛涗腑鏂囨敞閲
