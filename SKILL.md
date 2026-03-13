---
name: auto-video-analyzer
description: "自动分析视频内容。检测到视频分析请求时，自动复制视频、提取关键帧、进行AI视觉分析、生成报告并清理临时文件。支持扫描模式(快速概览)、完整模式(深度分析)、Debug模式(连续帧排查问题)。"
metadata:
  version: "1.0.0"
  author: "AI Assistant"
  requires:
    - ffmpeg
    - powershell
---

# Auto Video Analyzer

## 触发条件

当用户消息包含以下模式时自动调用：

| 模式 | 关键词 | 示例 |
|------|--------|------|
| Scan | "分析视频", "看一下视频", "说说视频内容" | "分析视频 C:\\video.mp4" |
| Full | "详细分析视频", "深度分析视频" | "详细分析视频 D:\\demo.mp4" |
| Debug | "Debug视频", "排查视频", "视频问题" | "Debug视频，为什么角色不动" |

## 工作流程

### 1. 解析视频路径
从用户消息中提取视频文件路径，支持：
- 绝对路径：`C:\Users\...\video.mp4`
- 相对路径：`videos/demo.mp4`
- 常见视频格式：mp4, avi, mov, webm, mkv

### 2. 执行分析脚本

首先确保已按"配套脚本"章节创建了 PowerShell 脚本，然后执行：

```powershell
# Scan 模式（默认）
.\tools\auto-analyze-video.ps1 -VideoPath "视频路径"

# 脚本会自动提取帧并生成分析报告
```

AI 助手会自动检测分析结果并读取帧图片进行视觉分析。

### 3. 提取帧策略

**Scan 模式**：
- 提取 ~8 张关键帧
- 均匀分布在视频时长中
- 适合快速了解视频内容

**Full 模式**：
- 开头 3 秒密集采样（6 帧，每秒 2 帧）
- 中间均匀采样（10 帧）
- 适合详细分析游戏流程、UI变化

**Debug 模式**：
- 每秒提取 2 帧（连续帧）
- 适合分析动画问题、对象移动轨迹

### 4. AI 帧分析

读取提取的帧图片，分析：
- 视频整体内容和场景
- 视觉元素（UI、角色、特效）
- 动作/动画流程
- 游戏机制（如果是游戏视频）
- 问题排查（Debug模式）

### 5. 清理临时文件

```powershell
# 手动清理分析目录
Remove-Item -Path "analysis/{视频名}" -Recurse -Force
```

或在分析完成后让 AI 助手自动清理。

## 输出格式

分析完成后返回：

```
## 视频分析报告

**视频文件**: xxx.mp4
**分析模式**: Scan/Full/Debug
**提取帧数**: N

### 内容概述
...

### 详细分析
...

### 技术建议（如适用）
...
```

## 使用示例

### 示例 1：快速分析
**用户**: 分析一下 C:\Users\Administrator\Videos\QQ202635-182914.mp4

**AI行动**:
1. 检测到 "分析" + 视频路径
2. 执行 Scan 模式提取帧
3. 分析帧内容
4. 返回报告并清理

**AI回复**: 
```
这是三国SLG游戏视频，展示了英雄切磋玩法...
[详细分析报告]
```

### 示例 2：Debug排查
**用户**: Debug视频 C:\bug.mp4，小兵为什么不移动

**AI行动**:
1. 检测到 "Debug视频" + 问题描述
2. 执行 Debug 模式提取连续帧
3. 逐帧对比分析
4. 定位问题原因

**AI回复**:
```
从第12帧到第18帧，小兵位置坐标未变化...
可能原因：1. 动画状态机卡住 2. 移动逻辑未触发...
```

### 示例 3：详细分析
**用户**: 详细分析视频 D:\game-demo.mp4

**AI行动**:
1. 检测到 "详细分析"
2. 执行 Full 模式提取16帧
3. 深度分析游戏机制

**AI回复**:
```
## 详细分析报告

### 游戏类型
竖屏SLG策略手游...

### UI布局分析
顶部资源栏、中部战斗区、底部操作区...

### 战斗流程
1. 远战回合：技能释放阶段...
2. 近战回合：兵力交锋阶段...
```

## 错误处理

| 错误情况 | 处理方式 |
|---------|---------|
| 视频文件不存在 | 提示用户检查路径 |
| FFmpeg 未安装 | 提示安装 FFmpeg |
| 视频格式不支持 | 尝试提取，失败则告知 |
| 磁盘空间不足 | 提示清理空间后重试 |

## 技术依赖

- **FFmpeg**: 视频信息读取和帧提取
  - ffprobe: 获取视频时长
  - ffmpeg: 提取关键帧
  
- **PowerShell**: 脚本执行和文件操作

- **AI Vision**: 图像分析能力

## 文件结构

```
skills/auto-video-analyzer/
├── SKILL.md              # 本文件 - 技能定义
└── README.md             # 使用说明

workspace/                # 需要手动创建以下脚本
tools/
└── auto-analyze-video.ps1   # 核心提取脚本（见"配套脚本"章节）
analysis/                 # 分析输出目录（自动生成）
└── {视频名}/
    ├── analysis-report.md   # 分析报告
    └── frames/              # 提取的帧图片
```

## 配置参数

可通过环境变量调整：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `VIDEO_SCAN_FRAMES` | 8 | Scan模式提取帧数 |
| `VIDEO_FULL_START_FRAMES` | 6 | Full模式开头密集帧数 |
| `VIDEO_FULL_MID_FRAMES` | 10 | Full模式中间采样帧数 |
| `VIDEO_DEBUG_FPS` | 2 | Debug模式每秒帧数 |

## 配套脚本

由于 ClawHub 只接受文本文件，PowerShell 脚本内容需手动创建。

### 创建分析脚本

在工作目录创建 `tools/auto-analyze-video.ps1`：

```powershell
#!/usr/bin/env pwsh
# Auto Video Analyzer - 全自动视频分析工具
# 用法: .\auto-analyze-video.ps1 <视频文件路径>

param(
    [Parameter(Mandatory=$true)]
    [string]$VideoPath
)

$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Error($msg) { Write-Host $msg -ForegroundColor Red }

# 检查视频文件
if (-not (Test-Path $VideoPath)) {
    Write-Error "❌ 视频文件不存在: $VideoPath"
    exit 1
}

$videoName = [System.IO.Path]::GetFileNameWithoutExtension($VideoPath)
$workspaceDir = $PSScriptRoot | Split-Path -Parent
$outputDir = Join-Path $workspaceDir "analysis" $videoName
$frameDir = Join-Path $outputDir "frames"

Write-Info "🎬 开始分析视频: $videoName"
Write-Info "   文件路径: $(Resolve-Path $VideoPath)"

# 创建输出目录
New-Item -ItemType Directory -Force -Path $frameDir | Out-Null

# 检查FFmpeg
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    Write-Error "❌ FFmpeg 未安装"
    Write-Info "   请运行: winget install Gyan.FFmpeg"
    exit 1
}

# 获取视频信息
Write-Info "📊 正在分析视频信息..."
try {
    $duration = [math]::Floor((& ffprobe -v error -show_entries format=duration -of csv=p=0 $VideoPath))
    $resolution = (& ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 $VideoPath)
    $fps = (& ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 $VideoPath)
    
    Write-Info "   时长: $duration 秒"
    Write-Info "   分辨率: $resolution"
    Write-Info "   帧率: $fps"
} catch {
    Write-Error "无法读取视频信息"
    exit 1
}

# 智能提取策略
Write-Info "🖼️  正在提取关键帧..."

# 策略: 开头3秒密集 + 中间均匀采样
$startDuration = [math]::Min(3, $duration)
$sampleCount = [math]::Min(12, [math]::Floor($duration / 2))  # 最多12张间隔帧
$interval = if ($duration -gt $startDuration) { 
    [math]::Floor(($duration - $startDuration) / $sampleCount) 
} else { 0 }

$frameList = @()

# 1. 提取开头密集帧 (理解开场)
if ($startDuration -gt 0) {
    Write-Info "   提取开头 ${startDuration}秒 (每秒2帧)..."
    & ffmpeg -i $VideoPath -t $startDuration -vf "fps=2,scale=1280:-1:flags=lanczos" -q:v 3 "$frameDir\frame_start_%03d.jpg" -y 2>$null
    $startFrames = Get-ChildItem $frameDir -Filter "frame_start_*.jpg"
    $frameList += $startFrames | ForEach-Object { $_.FullName }
    Write-Success "   ✓ 提取了 $($startFrames.Count) 张开场帧"
}

# 2. 提取中间采样帧 (了解整体)
if ($interval -gt 0 -and $sampleCount -gt 0) {
    Write-Info "   提取中间内容 (每${interval}秒1帧, 共${sampleCount}帧)..."
    
    for ($i = 0; $i -lt $sampleCount; $i++) {
        $timestamp = $startDuration + ($i * $interval)
        if ($timestamp -ge $duration) { break }
        
        $outputFrame = "$frameDir\frame_mid_$(($i+1).ToString('00')).jpg"
        & ffmpeg -ss $timestamp -i $VideoPath -vf "scale=1280:-1:flags=lanczos" -q:v 3 -frames:v 1 $outputFrame -y 2>$null
        
        if (Test-Path $outputFrame) {
            $frameList += $outputFrame
        }
    }
    Write-Success "   ✓ 提取了 $(($frameList.Count - $startFrames.Count)) 张中间帧"
}

# 生成分析报告框架
$analysisFile = Join-Path $outputDir "analysis-report.md"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$report = @"
# 视频分析报告

**分析时间**: $timestamp  
**视频文件**: $videoName  
**视频时长**: $duration 秒  
**分辨率**: $resolution  
**提取帧数**: $($frameList.Count)  

---

## 提取的帧列表

| 序号 | 时间戳 | 文件路径 |
|------|--------|----------|
"@

for ($i = 0; $i -lt $frameList.Count; $i++) {
    $frame = $frameList[$i]
    $frameName = Split-Path $frame -Leaf
    $isStart = $frameName -like "*start*"
    $timeInfo = if ($isStart) { "开头" } else { "中间" }
    $report += "| $($i+1) | $timeInfo | \`$frameDir\$frameName\` |\`n"
}

$report += @"

---

## AI 分析区域

> 请将以下帧图片发送给 AI 助手进行分析，或等待 AI 自动读取此报告。

### 开场画面分析
"@

# 添加开场帧引用
$startFrameNames = $frameList | Where-Object { $_ -like "*start*" } | ForEach-Object { Split-Path $_ -Leaf }
foreach ($frame in $startFrameNames) {
    $report += "- \`frames/$frame\``n"
}

$report += @"

### 关键帧分析
"@

$midFrameNames = $frameList | Where-Object { $_ -notlike "*start*" } | ForEach-Object { Split-Path $_ -Leaf }
foreach ($frame in $midFrameNames) {
    $report += "- \`frames/$frame\``n"
}

$report += @"

---

## 请 AI 回答以下问题

1. **视频内容概述**: 这个视频展示的是什么内容？
2. **视觉元素**: 有哪些UI组件、图形元素、动画效果？
3. **交互逻辑**: 能看出哪些用户交互或状态变化？
4. **技术建议**: 如果是H5游戏/应用，实现上有什么建议？

---

*报告由 Auto Video Analyzer 生成*
"@

$report | Out-File -FilePath $analysisFile -Encoding UTF8

Write-Success ""
Write-Success "✅ 视频分析准备完成!"
Write-Success ""
Write-Info "📁 输出目录: $outputDir"
Write-Info "📄 分析报告: $analysisFile"
Write-Info "🖼️  帧图片目录: $frameDir"
Write-Success ""
Write-Info "💡 下一步:"
Write-Info "   1. 查看提取的帧图片: explorer '$frameDir'"
Write-Info "   2. 让AI分析: 告诉AI助手 '分析视频 $videoName'"
Write-Success ""

# 显示帧列表
Write-Info "提取的帧文件:"
foreach ($frame in $frameList) {
    $size = (Get-Item $frame).Length / 1KB
    Write-Info "   📷 $(Split-Path $frame -Leaf) ($([math]::Round($size,1)) KB)"
}
```

### 安装步骤

1. **安装 FFmpeg** (必需):
   ```powershell
   winget install Gyan.FFmpeg
   ```

2. **创建脚本目录**:
   ```powershell
   mkdir -p ~/.openclaw/workspace/tools
   ```

3. **复制脚本内容**到 `~/.openclaw/workspace/tools/auto-analyze-video.ps1`

## 更新日志

### v1.0.0
- 基础视频分析功能
- 支持 Scan/Full/Debug 三种模式
- 自动提取帧、AI分析、自动清理
