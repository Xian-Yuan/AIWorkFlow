# Lyra + GAS 开发技能

本技能是为"用户提需求 → AI 自主完成架构设计 + 代码实现"模式设计的 OpenCode/Trae 技能。

## 安装

技能文件位于: `MLCase/.trae/skills/lyra-gas-dev/`

```
MLCase/.trae/skills/lyra-gas-dev/
├── SKILL.md              # 主技能定义 (入口)
├── references/           # 参考文档
│   ├── lyra-architecture-quickref.md  # Lyra 架构速查
│   ├── gas-quickref.md               # GAS 速查
│   └── docs-mapping.md               # 需求 → Docs 路径映射
└── agents/               # Agent 配置
    └── openai.yaml
```

## 使用方式

在与 AI 对话时，可以这么说：

```
@lyra-gas-dev 我需要创建一个火焰魔法技能，按 Q 键释放，
生成火球投射物，命中造成范围伤害。多人对战游戏。
```

AI 会自动：
1. 参考 CodeTemplates/NewGameplayAbility/ 中的模板
2. 查阅 APIRef/GASCoreClasses.md 确认精确 API 签名
3. 生成完整的 .h/.cpp/.uplugin/Build.cs 文件
4. 列出所有蓝图配置步骤

## 文档依赖

本技能依赖 `G:\UEGameDevelopment\Docs\` 中的完整文档库：

```
Docs/
├── CodeTemplates/   ← 完整代码模板 (最高优先级)
├── APIRef/          ← 精确 API 签名
├── ConfigRef/       ← 配置文件参考
├── Lyra/            ← Lyra 架构说明
├── GAS/             ← GAS 架构说明
├── Troubleshooting/ ← 错误排查
├── UE5/ UE5.7/      ← UE 通用开发
└── Community/       ← 社区资源
```
