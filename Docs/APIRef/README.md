# API Reference

本文档目录包含 UE5/Lyra/GAS 的精确 API 签名，用于防止 AI 代码生成时的幻觉。

## 文件索引

| 文件 | 内容 | 何时查阅 |
|------|------|---------|
| `LyraCoreClasses.md` | Lyra 15 个核心类的 public 函数签名 | 调用 Lyra 类方法前 |
| `GASCoreClasses.md` | GAS 7 个核心类的 public 函数签名 + AbilityTask 索引 | 调用 GAS 类方法前 |
| `AbilityTaskSignatures.md` | 11 个 AbilityTask 完整 Create 签名 + 参数说明 | 写 AbilityTask 代码前 |
| `UECommonAPIRef.md` | UGameplayStatics / KismetSystem / KismetMath 高频 API | 调用通用引擎函数前 |
| `UEMacrosRef.md` | UE 宏全谱（UCLASS/UPROPERTY/UFUNCTION §15 Blueprint 互操作速查） | 写宏/反射代码前 |
| `CommonPatterns.md` | 10 种常用代码模式（复制即用） | 需要标准模式模板时 |

## 核心规则

**绝对禁止凭记忆写函数调用。调用前必须在此目录中核对签名。**
