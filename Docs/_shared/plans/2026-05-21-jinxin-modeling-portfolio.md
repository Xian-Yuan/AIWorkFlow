# JinXin Modeling Portfolio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate a 3-slide PowerPoint portfolio with an industrial-tech visual style using the six images in `Project/PPT`.

**Architecture:** Use a PowerShell script with PowerPoint COM automation so the output is a native `.pptx` file without adding project dependencies. Centralize slide styling in helper functions, then place images section-by-section in the required order: project showcase, single model showcase, topology showcase.

**Tech Stack:** PowerShell 5, Microsoft PowerPoint COM automation

---

### Task 1: Create generation script

**Files:**
- Create: `Project/PPT/generate_portfolio_ppt.ps1`

- [ ] **Step 1: Add script parameters and shared slide helpers**

```powershell
param(
    [string]$RootPath = "g:\UEGameDevelopment\Project\PPT",
    [string]$OutputPath = "g:\UEGameDevelopment\Project\PPT\JinXin_Modeling_Portfolio.pptx"
)
```

- [ ] **Step 2: Add helper functions for styling**

```powershell
function Add-TitleBlock { }
function Add-ImageCover { }
function Add-AccentFrame { }
```

- [ ] **Step 3: Add slide generation in required order**

```powershell
$slides = @(
    @{ Title = "金鑫建模作品集"; Section = "项目内容展示"; Images = @("项目内容展示\产线.png", "项目内容展示\火发项目.png") }
    @{ Title = "单体模型展示"; Section = "Single Model"; Images = @("单体模型展示\分拣存储机.jpg", "单体模型展示\鸿雁无人机.png") }
    @{ Title = "拓扑展示"; Section = "Topology"; Images = @("拓扑展示\汽车白模.jpg", "拓扑展示\汽车烘焙.jpg") }
)
```

- [ ] **Step 4: Save and close the presentation**

```powershell
$presentation.SaveAs($OutputPath)
$presentation.Close()
$powerPoint.Quit()
```

### Task 2: Generate the presentation

**Files:**
- Modify: `Project/PPT/generate_portfolio_ppt.ps1`
- Create: `Project/PPT/JinXin_Modeling_Portfolio.pptx`

- [ ] **Step 1: Run the generator**

```powershell
powershell -ExecutionPolicy Bypass -File "g:\UEGameDevelopment\Project\PPT\generate_portfolio_ppt.ps1"
```

- [ ] **Step 2: Verify expected output**

Expected result:

```text
Created g:\UEGameDevelopment\Project\PPT\JinXin_Modeling_Portfolio.pptx
```

### Task 3: Sanity check output

**Files:**
- Verify: `Project/PPT/JinXin_Modeling_Portfolio.pptx`

- [ ] **Step 1: Open file metadata through PowerPoint COM**

```powershell
$ppt = New-Object -ComObject PowerPoint.Application
$presentation = $ppt.Presentations.Open("g:\UEGameDevelopment\Project\PPT\JinXin_Modeling_Portfolio.pptx", $false, $true, $false)
$presentation.Slides.Count
```

- [ ] **Step 2: Confirm there are 3 slides and close cleanly**

Expected result:

```text
3
```
