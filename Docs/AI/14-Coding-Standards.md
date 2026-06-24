---
domain: ue
domain_path: ue/gas-lyra
kg_node_id: node.doc-ai-ai-14-coding-standards-b500
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.14-coding-standards.b500

---

# C++编码规范与命名约定（Coding Standards）

## 语言与命名
- 文件名与类名：英文命名；类名前缀 A/U/S/F/E（Actor/UObject/Struct/Struct/Enum）
- 变量与函数：英文命名；中文注释；避免缩写与不明语义
- 常量与枚举：使用 PascalCase（枚举项 EType::Value 格式）

## 头文件与包含
- 包含顺序：同文件头  相关模块头  标准库头  最后引擎头（必要时）
- 前向声明：优先使用以降低编译耦合
- 禁止循环依赖：模块与类间避免互相包含

## UCLASS/UPROPERTY/UFUNCTION 基本规范
- 仅在需要反射/序列化/蓝图时添加宏
- UPROPERTY 指针使用 TObjectPtr/TWeakObjectPtr；避免原始裸指针长期持有
- Blueprint 友好：Category 分类清晰；参数尽量为 const 引用；返回值语义明确

## 资源与路径
- 使用相对资源引用（Content路径）与软引用（SoftObject/SoftClass）管理非必需加载资源

## 日志与错误处理
- 使用 UE_LOG，统一 Category；避免重复 TEXT 宏嵌套
- 对外接口进行参数校验（nullptr 检查、范围检查）

## 单机项目限制
- 不使用 UFUNCTION(Server/Client/NetMulticast) 等网络宏
- 不使用 UPROPERTY(Replicated) 等复制相关标记
- 避免任何网络子系统依赖

## 文本与本地化（Localization）
- 所有用户可见文本必须使用 `FText`，禁止使用 `FString`/`std::string` 显示文案。
- 固定文案统一使用 `LOCTEXT/NSLOCTEXT`，禁止 `FText::FromString("...")` 承载 UI 文案。
- 数据驱动文案使用“字符串表”（String Table），通过 `FText::FromStringTable(TableId, Key)` 获取本地化文本；UMG/蓝图 Text 属性选择“From String Table”。
- 文本格式化使用 `FText::Format`、`FText::AsNumber/AsPercent/AsDateTime` 等，确保不同文化下自动格式化。
- 业务逻辑与显示分离：禁止用显示文本做逻辑判断（如比较 "Enable/On/True"）；使用枚举/布尔/标签。
- Localization Dashboard 管理收集/翻译/构建：添加 `en-US` 与 `zh-CN`，生成 `.locres` 并随打包部署。
- 默认与运行时文化：在 `DefaultGame.ini` 配置默认 `Culture`；运行时用 `FInternationalization::Get().SetCurrentCulture("zh-CN"/"en-US")` 切换。
- 字体与中文显示：使用 Composite Font 覆盖中英字形；避免依赖大型 Fallback 字体导致首帧同步加载。
