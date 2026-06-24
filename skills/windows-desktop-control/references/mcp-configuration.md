# MCP Server Configuration Reference

## mcp.json 位置

`.tools/hermes-worker/profiles/jinli-implementer/mcp.json`

## 完整配置

```json
{
  "mcpServers": {
    "jinli-workflow": {
      "command": "python",
      "args": ["-m", "jinli_workflow"],
      "cwd": "E:/UEGameDevelopment/.trae/hermes/mcp"
    },
    "windows-computer-use": {
      "command": "python",
      "args": ["-m", "windows_computer_use"],
      "cwd": "E:/UEGameDevelopment/.trae/hermes/mcp"
    },
    "desktop-commander": {
      "command": "node",
      "args": ["D:/npm-global/node_modules/@wonderwhy-er/desktop-commander/dist/index.js"]
    },
    "unreal-mcp": {
      "command": "python",
      "args": ["-m", "unreal_mcp"],
      "cwd": "E:/UEGameDevelopment/.trae/hermes/mcp"
    }
  }
}
```

## MCP Server 代码位置

| Server | 路径 |
|--------|------|
| windows-computer-use | `.trae/hermes/mcp/windows_computer_use/` |
| unreal-mcp | `.trae/hermes/mcp/unreal_mcp/` |
| jinli-workflow | `.trae/hermes/mcp/jinli_workflow/` |
| desktop-commander | npm global: `D:/npm-global/node_modules/@wonderwhy-er/desktop-commander/` |

## 依赖安装

```bash
# windows-computer-use
pip install pywinauto pyautogui Pillow mcp

# desktop-commander
npm install -g @wonderwhy-er/desktop-commander

# unreal-mcp (仅 Python MCP SDK，UE Plugin 另外安装)
pip install mcp
```

## unreal-mcp 连接参数

- Host: 127.0.0.1
- Port: 55557
- 需 UE5 Editor 运行 + unreal-mcp UE Plugin 已安装并激活

## 备份

修改前备份：`mcp.json.bak.20260621`
