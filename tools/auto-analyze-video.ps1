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
    $report += "| $($i+1) | $timeInfo | `$frameDir\$frameName` |`n"
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
