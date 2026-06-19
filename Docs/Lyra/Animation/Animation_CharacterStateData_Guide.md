# Animation Character State Data Guide

鏈寚鍗椾粙缁?JMAnimInstance::UpdateCharacterStateData 鍦?UE5.7 鍗曟満椤圭洰涓殑浣跨敤鏂瑰紡涓庢敞鎰忎簨椤广€?
## Overview锛堟瑙堬級

UJMAnimInstance 鏂板浜嗕互涓?Blueprint 鍙嬪ソ鐨勭姸鎬佹暟鎹細
- bIsOnGround锛堟槸鍚﹀湪鍦伴潰锛?- bIsCrouching锛堟槸鍚﹁共浼忥級
- bIsJumping锛堟槸鍚﹁烦璺冿級
- bIsFalling锛堟槸鍚︿笅钀斤級
- bIsADS锛堟槸鍚︾瀯鍑嗭紝Aiming Down Sights锛?- TimeSinceFiredWeapon锛堣窛绂讳笂娆″紑鐏殑鏃堕棿锛岀锛?
骞舵彁渚涚嚎绋嬪畨鍏ㄧ殑鏇存柊涓庤幏鍙栨帴鍙ｏ細
- UpdateCharacterStateData(DeltaTime) [BlueprintThreadSafe]
- GetIsOnGround/GetIsCrouching/GetIsJumping/GetIsFalling/GetIsADS [BlueprintThreadSafe]
- NotifyWeaponFired() 鐢ㄤ簬娓告垙绾跨▼涓婃姤寮€鐏簨浠?
## ADS via GameplayTag锛堥€氳繃 GameplayTag 鍒ゅ畾 ADS锛?
- 鍦?AnimInstance 涓厤缃?ADSGameplayTag锛圗ditAnywhere锛夈€?- 绯荤粺浼氫粠 OwningActor 涓婅幏鍙?AbilitySystemComponent锛屽苟鏌ヨ璇ユ爣绛撅細
  - ASC->HasMatchingGameplayTag(ADSGameplayTag) 鎴?ASC->GetTagCount(ADSGameplayTag) > 0
- 鎻愪緵 ADSFallbackTimeout锛堥粯璁?0.10s锛夌敤浜庢爣绛炬姈鍔ㄧ殑鐭殏淇濇寔銆?
娉ㄦ剰锛氭湰椤圭洰涓哄崟鏈猴紝ASC 鏍囩闇€鍦ㄦ湰鍦拌兘鍔?杈撳叆閫昏緫涓淮鎶わ紙Loose Tag 璁℃暟鎴栬兘鍔涙縺娲绘坊鍔?绉婚櫎锛夈€?
## Movement State锛堢Щ鍔ㄧ姸鎬侊級

- 浣跨敤 CharacterMovementComponent 鐨勫彧璇绘煡璇細
  - IsMovingOnGround 鈫?bIsOnGround
  - IsCrouching 鈫?bIsCrouching
  - IsFalling 鈫?鍙備笌 bIsFalling 鍒ゅ畾
- Z 閫熷害闃堝€硷細
  - JumpMinZVelocity锛堥粯璁?50 cm/s锛?  - FallMinZVelocity锛堥粯璁?50 cm/s锛屽唴閮ㄦ寜璐熷€兼瘮杈冿級

## AnimBP Call Order锛堝姩鐢昏摑鍥捐皟鐢ㄩ『搴忓缓璁級

1) Blueprint Thread Safe Update Animation 闃舵锛?   - UpdateVelocityData 鈫?UpdateAccelerationData 鈫?UpdateCharacterStateData
2) AnimGraph 浣跨敤 Property Access 浼樺厛璇诲彇涓婅堪 UPROPERTY锛岄伩鍏嶄簨浠跺浘杩囧害閫昏緫銆?
## Debug Logs锛堣皟璇曟棩蹇楋級

- bEnableStateDebugLogs 榛樿寮€鍚紙鎸夌敤鎴峰亸濂斤級銆?- 缂哄皯 Pawn/MovementComponent/ASC 鏃朵細鎵撳嵃璀﹀憡锛屼究浜庡揩閫熷畾浣嶆帴绾块棶棰樸€?
## Performance锛堟€ц兘褰卞搷锛?
- 绾鎿嶄綔涓庢湰鍦拌祴鍊硷紝CPU 寮€閿€鏋佷綆锛?0.1ms/甯э紝鍏稿瀷锛夈€?- 鏃犲唴瀛樺垎閰嶄笌纾佺洏 I/O锛涙棤缃戠粶澶嶅埗/RPC锛涚鍚堝崟鏈洪檺鍒躲€?
## Error Prevention锛堥敊璇闃诧級

- Null 淇濇姢锛歅awn/MovementComponent/ASC 鍧囪繘琛岀┖鎸囬拡妫€鏌ャ€?- 绾跨▼瀹夊叏锛氬嚱鏁版爣娉?BlueprintThreadSafe锛屼粎浣跨敤鍙鏌ヨ涓庢湰鍦拌祴鍊笺€?- 骞冲彴锛歐indows/UE5.7 宸ュ叿閾撅紝閬靛惊椤圭洰瑙勮寖涓庢枃妗ｃ€?
## Example锛堢ず渚嬶級

Blueprint 璁剧疆锛?- 鍦?AnimInstance锛堟垨鍏跺瓙绫伙級涓皢 ADSGameplayTag 璁剧疆涓鸿嚜瀹氫箟鐨?ADS 鏍囩锛堜緥濡傦細Lyra.Gameplay.ADS锛夈€?- 鍦ㄨ兘鍔涙垨杈撳叆閫昏緫涓淮鎶よ鏍囩璁℃暟锛氭寜鍘嬬瀯鍑嗛敭 鈫?娣诲姞鏍囩锛涢噴鏀?鈫?绉婚櫎鏍囩銆?- 寮€鐏椂璋冪敤 AnimInstance.NotifyWeaponFired()锛岀敤浜?TimeSinceFiredWeapon 鐨勮绠椼€
