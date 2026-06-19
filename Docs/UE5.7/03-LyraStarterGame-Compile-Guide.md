# UE5.7 编译说明（LyraStarterGame）

本文件记录在 UE5.7 环境下编译 LyraStarterGame 的完整流程与注意事项，旨在标准化构建过程、降低出错率、便于新成员快速上手。

---

## 1. 目标与适用范围
- 引擎版本：UE 5.7（严格使用指定版本的 UBT）
- 项目路径：g:\Project\LyraStarterGame - 5.7
- 适用平台：Win64
- 配置：Development
- 说明对象：单机项目（严格禁止引入网络复制/RPC相关内容）

## 2. 环境与工具位置
- UnrealBuildTool(UBT)：
  - 绝对路径：G:\UE_5.7\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe
- 项目文件（.uproject）：
  - 绝对路径：g:\Project\LyraStarterGame - 5.7\LyraStarterGame.uproject
- 推荐开发工具链：
  - Visual Studio 2022（含 Desktop development with C++）
  - Windows 10/11 SDK
  - .NET 运行时（随 UE 安装）

## 3. 快速验证（避免路径或环境错误）
在 PowerShell 中执行：
`powershell
# 验证 UBT 存在
Test-Path "G:\\UE_5.7\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.exe"
# 验证项目文件存在
Test-Path "g:\\Project\\LyraStarterGame - 5.7\\LyraStarterGame.uproject"
`
两项均返回 True 后再进行编译。

## 4. 标准编译指令（UE5.7）
在项目根目录执行（PowerShell）：
`powershell
& "G:\\UE_5.7\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.exe" LyraGame Win64 Development "g:\\Project\\LyraStarterGame - 5.7\\LyraStarterGame.uproject" -WaitMutex -FromMsBuild
`
参数说明：
- LyraGame：目标模块/目标名（Target）
- Win64：目标平台
- Development：编译配置（可选：DebugGame/Shipping 等）
- .uproject：指定项目文件绝对路径
- -WaitMutex -FromMsBuild：确保与并发构建工具配合、稳定输出

## 5. 编译输出与结果
- 产物目录：g:\Project\LyraStarterGame - 5.7\Binaries\Win64\
  - 典型文件：LyraGame.exe, LyraGame.lib, LyraGame.pdb, LyraGame.exp
- 成功日志关键字：Result: Succeeded
- 示例（截断）：
`
[323/324] Link [x64] LyraGame.exe (...)
Result: Succeeded
Total execution time: 257.85 seconds
`

## 6. 注意事项（单机项目与UE5.7特化）
- 严格使用 UE5.7 的 UBT 路径（避免使用其他版本）
- 关闭 Unreal Editor 后再编译，避免文件锁定导致链接失败
- 使用绝对路径（避免相对路径导致的工作目录不一致）
- 不进行任何 Git 历史/缓存/清理/合并/回档操作（除非明确要求）
- 不引入网络复制、RPC 等功能（单机项目限制）
- 如涉及新增 C++ 源文件，建议先完整生成项目文件再编译

## 7. 常见问题与故障排除
- 问题：License not activated（XGE 分布式编译警告）
  - 说明：不影响本地构建；可忽略或禁用分布式编译
- 问题：cannot open input file/链接失败
  - 检查：是否有编辑器未关闭、路径是否存在、是否有权限
- 问题：missing SDK 或工具链错误
  - 安装：VS2022 C++工具链、Windows SDK；重启 PowerShell/VS 后重试
- 问题：Target 或模块名错误
  - 确认：LyraGame 是否为正确目标；查看 Source/ 下 Target.cs 文件
- 问题：权限不足导致写入失败
  - 方案：以管理员身份运行 PowerShell 或将工程移动到非受限路径

## 8. 增量编译与完整编译建议
- 增量编译：小范围代码改动时使用，速度更快
- 完整编译：新增模块/大规模改动时使用，确保一致性

## 9. 变更记录与维护建议
- 若引擎路径、目标名、平台或配置变化，请同步更新本文件
- 建议在 Documentation 文件夹下维护更多规范文档（如 UE5_Error_Prevention_Guide.md）并进行交叉引用

## 10. 本次编译记录（示例）
- 时间：参考构建日志时间
- 使用命令：见第4节
- 结果：Succeeded
- 产物：Binaries\Win64\LyraGame.exe 等

---

维护者：项目组
版本：v1.0（UE5.7）

