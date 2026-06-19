# Handover 跨会话摘要模板

## 用法
每次开新会话前，用以下模板保存关键上下文：

```
# 上轮摘要 — [日期]

## 已完成
- [主要产出1]
- [主要产出2]

## 当前状态
- [文件/模块] 进展到 [阶段]
- 最后修改: [文件路径]

## 下一步
1. [任务1]
2. [任务2]

## 已知问题
- [问题描述] — [临时解决方案]
- [阻塞项]

## 关键决策
- [决策] — [原因]
```

## 触发时机
- /clear 前
- 对话超过 20 条消息
- 感觉模型开始"忘记"早期指令
- Token 使用率超过 60%

## 示例
```
# 上轮摘要 — 2026-05-25

## 已完成
- RBAC User/Role/Permission 三表 + Prisma Schema
- 按钮级权限 Guard
- super_admin 绕过逻辑

## 当前状态
- auth 模块在 src/modules/auth/
- 最后修改: src/modules/auth/auth.service.ts L156

## 下一步
1. refreshToken 落库
2. 踢下线功能
3. 前端权限指令

## 已知问题
- Prisma 嵌套 create 报错 — 已改为逐条 create

## 关键决策
- refreshToken 用 Redis 而非数据库 — 性能要求
```
