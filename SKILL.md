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

```powershell
# Scan 模式（默认）
.\tools\smart-video-analyzer.ps1 -SourceVideoPath "视频路径" -Mode scan

# Full 模式
.\tools\smart-video-analyzer.ps1 -SourceVideoPath "视频路径" -Mode full

# Debug 模式
.\tools\smart-video-analyzer.ps1 -SourceVideoPath "视频路径" -Mode debug
```

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
Remove-Item -Path "temp/{分析ID}" -Recurse -Force
```

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
├── README.md             # 使用说明
└── (可选) scripts/       # 辅助脚本

workspace/
├── tools/
│   └── smart-video-analyzer.ps1   # 核心提取脚本
└── temp/                 # 临时目录（自动清理）
    └── {分析ID}/
        ├── video.mp4
        └── frames/
            ├── frame_01.jpg
            └── ...
```

## 配置参数

可通过环境变量调整：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `VIDEO_SCAN_FRAMES` | 8 | Scan模式提取帧数 |
| `VIDEO_FULL_START_FRAMES` | 6 | Full模式开头密集帧数 |
| `VIDEO_FULL_MID_FRAMES` | 10 | Full模式中间采样帧数 |
| `VIDEO_DEBUG_FPS` | 2 | Debug模式每秒帧数 |

## 更新日志

### v1.0.0
- 基础视频分析功能
- 支持 Scan/Full/Debug 三种模式
- 自动提取帧、AI分析、自动清理
