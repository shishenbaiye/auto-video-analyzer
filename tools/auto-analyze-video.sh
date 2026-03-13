#!/bin/bash
# Auto Video Analyzer - 全自动视频分析工具 (Linux/macOS 版)
# 用法: ./auto-analyze-video.sh <视频文件路径>

set -e

# 颜色输出函数
write_info() { echo -e "\033[36m$1\033[0m"; }
write_success() { echo -e "\033[32m$1\033[0m"; }
write_error() { echo -e "\033[31m$1\033[0m"; }

# 检查参数
if [ $# -lt 1 ]; then
    write_error "❌ 请提供视频文件路径"
    echo "用法: $0 <视频文件路径>"
    exit 1
fi

VideoPath="$1"

# 检查视频文件
if [ ! -f "$VideoPath" ]; then
    write_error "❌ 视频文件不存在: $VideoPath"
    exit 1
fi

# 获取视频文件名（不含扩展名）
videoName=$(basename "$VideoPath" | sed 's/\.[^.]*$//')

# 确定工作目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspaceDir=$(dirname "$SCRIPT_DIR")
outputDir="$workspaceDir/analysis/$videoName"
frameDir="$outputDir/frames"

# 获取绝对路径（兼容没有 realpath 的系统）
if command -v realpath &> /dev/null; then
    videoPathAbs=$(realpath "$VideoPath" 2>/dev/null || echo "$VideoPath")
elif command -v readlink &> /dev/null; then
    videoPathAbs=$(readlink -f "$VideoPath" 2>/dev/null || echo "$VideoPath")
else
    videoPathAbs="$VideoPath"
fi

write_info "🎬 开始分析视频: $videoName"
write_info "   文件路径: $videoPathAbs"

# 创建输出目录
mkdir -p "$frameDir"

# 检查 FFmpeg
if ! command -v ffmpeg &> /dev/null; then
    write_error "❌ FFmpeg 未安装"
    write_info "   请安装 FFmpeg:"
    write_info "     macOS: brew install ffmpeg"
    write_info "     Ubuntu/Debian: sudo apt install ffmpeg"
    write_info "     CentOS/RHEL: sudo yum install ffmpeg"
    exit 1
fi

if ! command -v ffprobe &> /dev/null; then
    write_error "❌ ffprobe 未找到（通常随 FFmpeg 一起安装）"
    exit 1
fi

# 获取视频信息
write_info "📊 正在分析视频信息..."
duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VideoPath" | awk '{print int($1)}')
resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$VideoPath")
fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$VideoPath")

write_info "   时长: $duration 秒"
write_info "   分辨率: $resolution"
write_info "   帧率: $fps"

# 智能提取策略
write_info "🖼️  正在提取关键帧..."

# 策略: 开头3秒密集 + 中间均匀采样
startDuration=$((duration < 3 ? duration : 3))
sampleCount=$((duration / 2))
[ $sampleCount -gt 12 ] && sampleCount=12

if [ $duration -gt $startDuration ] && [ $sampleCount -gt 0 ]; then
    interval=$(((duration - startDuration) / sampleCount))
else
    interval=0
fi

frameList=()

# 1. 提取开头密集帧 (理解开场)
if [ $startDuration -gt 0 ]; then
    write_info "   提取开头 ${startDuration}秒 (每秒2帧)..."
    ffmpeg -i "$VideoPath" -t $startDuration -vf "fps=2,scale=1280:-1:flags=lanczos" -q:v 3 "$frameDir/frame_start_%03d.jpg" -y 2>/dev/null || true
    
    startFrames=$(find "$frameDir" -name "frame_start_*.jpg" 2>/dev/null | wc -l)
    write_success "   ✓ 提取了 ${startFrames} 张开场帧"
fi

# 2. 提取中间采样帧 (了解整体)
if [ $interval -gt 0 ] && [ $sampleCount -gt 0 ]; then
    write_info "   提取中间内容 (每${interval}秒1帧, 共${sampleCount}帧)..."
    
    for ((i=0; i<sampleCount; i++)); do
        timestamp=$((startDuration + i * interval))
        [ $timestamp -ge $duration ] && break
        
        outputFrame=$(printf "$frameDir/frame_mid_%02d.jpg" $((i+1)))
        ffmpeg -ss $timestamp -i "$VideoPath" -vf "scale=1280:-1:flags=lanczos" -q:v 3 -frames:v 1 "$outputFrame" -y 2>/dev/null || true
        
        if [ -f "$outputFrame" ]; then
            frameList+=("$outputFrame")
        fi
    done
    
    midCount=${#frameList[@]}
    write_success "   ✓ 提取了 ${midCount} 张中间帧"
fi

# 收集所有帧
allFrames=("$frameDir"/frame_*.jpg)
totalFrames=${#allFrames[@]}

# 生成分析报告框架
analysisFile="$outputDir/analysis-report.md"
timestamp=$(date "+%Y-%m-%d %H:%M:%S")

cat > "$analysisFile" << EOF
# 视频分析报告

**分析时间**: $timestamp  
**视频文件**: $videoName  
**视频时长**: $duration 秒  
**分辨率**: $resolution  
**提取帧数**: $totalFrames  

---

## 提取的帧列表

| 序号 | 时间戳 | 文件路径 |
|------|--------|----------|
EOF

# 添加帧列表到报告
idx=1
for frame in "$frameDir"/frame_*.jpg; do
    if [ -f "$frame" ]; then
        frameName=$(basename "$frame")
        if [[ "$frameName" == *"start"* ]]; then
            timeInfo="开头"
        else
            timeInfo="中间"
        fi
        echo "| $idx | $timeInfo | \`frames/$frameName\` |" >> "$analysisFile"
        ((idx++))
    fi
done

cat >> "$analysisFile" << EOF

---

## AI 分析区域

> 请将以下帧图片发送给 AI 助手进行分析，或等待 AI 自动读取此报告。

### 开场画面分析
EOF

# 添加开场帧引用
for frame in "$frameDir"/frame_start_*.jpg; do
    if [ -f "$frame" ]; then
        frameName=$(basename "$frame")
        echo "- \`frames/$frameName\`" >> "$analysisFile"
    fi
done

echo "" >> "$analysisFile"
echo "### 关键帧分析" >> "$analysisFile"
echo "" >> "$analysisFile"

# 添加中间帧引用
for frame in "$frameDir"/frame_mid_*.jpg; do
    if [ -f "$frame" ]; then
        frameName=$(basename "$frame")
        echo "- \`frames/$frameName\`" >> "$analysisFile"
    fi
done

cat >> "$analysisFile" << EOF

---

## 请 AI 回答以下问题

1. **视频内容概述**: 这个视频展示的是什么内容？
2. **视觉元素**: 有哪些UI组件、图形元素、动画效果？
3. **交互逻辑**: 能看出哪些用户交互或状态变化？
4. **技术建议**: 如果是H5游戏/应用，实现上有什么建议？

---

*报告由 Auto Video Analyzer 生成*
EOF

write_success ""
write_success "✅ 视频分析准备完成!"
write_success ""
write_info "📁 输出目录: $outputDir"
write_info "📄 分析报告: $analysisFile"
write_info "🖼️  帧图片目录: $frameDir"
write_success ""
write_info "💡 下一步:"
write_info "   1. 查看提取的帧图片: open '$frameDir'"
write_info "   2. 让AI分析: 告诉AI助手 '分析视频 $videoName'"
write_success ""

# 显示帧列表
write_info "提取的帧文件:"
for frame in "$frameDir"/frame_*.jpg; do
    if [ -f "$frame" ]; then
        frameName=$(basename "$frame")
        size=$(du -h "$frame" 2>/dev/null | cut -f1)
        write_info "   📷 $frameName ($size)"
    fi
done
