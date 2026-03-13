#!/usr/bin/env pwsh
# Auto Video Analyzer - Quick Call Script
# 供AI直接调用，简化参数

param(
    [Parameter(Mandatory=$true)]
    [string]$VideoPath,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("scan", "full", "debug")]
    [string]$Mode = "scan"
)

# 调用主分析脚本
$result = & "$PSScriptRoot\..\..\tools\smart-video-analyzer.ps1" `
    -SourceVideoPath $VideoPath `
    -Mode $Mode | ConvertFrom-Json

if ($result.success) {
    # 返回帧文件列表供AI分析
    Write-Output "ANALYSIS_READY"
    Write-Output "TempID: $($result.tempId)"
    Write-Output "FrameCount: $($result.frameCount)"
    Write-Output "FrameDir: $($result.frameDir)"
    Write-Output "---FRAMES---"
    foreach ($frame in $result.frames) {
        Write-Output $frame
    }
} else {
    Write-Error "Analysis failed"
    exit 1
}
