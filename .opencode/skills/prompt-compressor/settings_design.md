# AI 模型设置面板

> 用户可通过设置页面配置可用的 AI 模型。配置持久化到 localStorage `characterPromptAISettings`。

---

## 数据结构

```json
{
  "activeModel": "deepseek-v4",
  "models": [
    {
      "id": "deepseek-v4",
      "name": "DeepSeek V4",
      "type": "text",
      "endpoint": "https://api.deepseek.com/v1/chat/completions",
      "enabled": true
    },
    {
      "id": "deepseek-v4-flash",
      "name": "DeepSeek V4 Flash",
      "type": "text",
      "endpoint": "https://api.deepseek.com/v1/chat/completions",
      "enabled": true
    }
  ],
  "parameters": {
    "temperature": 0.7,
    "maxTokens": 2000
  }
}
```

## 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| activeModel | string | 当前使用的模型ID |
| models[].id | string | 模型唯一标识 |
| models[].name | string | UI 显示名称 |
| models[].type | "text"/"image" | 文本生成或图像生成 |
| models[].endpoint | string | API 地址 |
| models[].enabled | bool | 是否启用（禁用后不在下拉菜单中显示） |
| parameters.temperature | 0-2 | 创造性程度（0=确定, 2=随机） |
| parameters.maxTokens | int | 最大输出长度 |

## 设置项

用户在设置面板中可配置：

| 设置项 | 类型 | 说明 |
|--------|------|------|
| **活跃模型** | 下拉选择 | 从已启用的模型中选择 |
| **添加模型** | 表单 | ID + 名称 + 类型 + 端点 |
| **启用/禁用** | 开关 | 控制模型是否出现在选择列表中 |
| **删除模型** | 按钮 | 移除自定义模型（内置模型不可删除） |
| **Temperature** | 滑块 | 0-2，步长0.1 |
| **Max Tokens** | 数字输入 | 输出长度上限 |
| **API Key** | 密码输入 | 各模型独立存储（localStorage加密） |

## 默认内置模型

以下模型不可删除，仅可禁用：

| ID | 名称 | 类型 |
|----|------|------|
| deepseek-v4 | DeepSeek V4 | text |
| deepseek-v4-flash | DeepSeek V4 Flash | text |

## 与提示词生成联动的规则

- 生成提示词时，读取 `activeModel` 决定使用哪个模型
- 如果 `activeModel` 对应的模型被禁用，回退到第一个启用的模型
- 每个模型可配置不同的 `temperature` 和 `maxTokens`
