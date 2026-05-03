# <slug>

## 用户需求
<原话或清洗后，≤ 3 行>

## 参考来源
- 参考站：<URL 或 "无 (从零设计)">
- 拆解报告：<refs/<slug>/analysis.md 或 "无">

## 1. 页面分区
<列每屏高度 + 一句话用途。栈式纵向布局或 fullpage 风都列清楚>
- [hero] 100vh — <用途>
- [section-1] <vh> — <用途>
- ...

## 2. 组件树
<伪代码树，给执行者拆文件用。组件命名按 PascalCase>
```
App
├── Hero
│   ├── BackgroundCanvas      // 见 §4.1
│   ├── HeadlineGroup         // 见 §4.2
│   └── ScrollIndicator
├── SectionFeatures
└── ...
```

## 3. 设计 token
- 主色 / 辅色 / 背景 / 文字（含 hex + 用途）
- 字体（family / 字号阶梯 / weight）
- 断点（desktop ≥1440 / laptop ≥1024 / tablet ≥768 / mobile <768）
- 间距栅格 / 圆角 / 阴影 / z-index 层级表

## 4. 动效规格（每个动效一节，参数化必填）
<禁止"流畅自然"虚词。每节必含：实现库 / 触发条件 / 起止状态 / duration / easing / 性能预算>
<**编号规则**：追加新动效用递增编号（4.10 / 4.11 ...），禁覆盖既有节；删动效保留节号写「已删除（YYYY-MM-DD 由 X 决定）」避免下游重编号串位>

### 4.1 <动效名>
- 实现：<r3f / framer-motion / gsap / css>
- 触发：<mount / hover / scroll start "top 80%" / mousemove>
- 起止：<opacity 0→1, translateY 60→0> 等
- duration / easing：<0.8s / cubic-bezier(...) 或 power2.out>
- 性能：<主线程占用 / FPS 目标 / GPU 层>
- 占位资产：<如有，标注 §5 哪一项>

## 5. 资产清单（占位 + 待替换）
| 占位 | 真品规格 | 当前占位实现 | 替换方式 |
|---|---|---|---|
| hero.glb | <5MB 单网格 | drei `<Icosahedron>` | 替换 src/assets/hero.glb |
| bg-loop.mp4 | 1920x1080 H.265 8s loop | CSS 渐变 + canvas 粒子 | 替换 src/components/BgVideo.tsx 内 src |
| icons/* | 自定义 SVG 12 个 | lucide-react | 替换 src/icons/ 目录 |

## 6. 可访问性
- prefers-reduced-motion：<具体哪些动效降级 / 关掉>
- 键盘导航：<焦点顺序 / 焦点可见样式>
- 对比度：<主文字 ≥ 4.5:1 实证>
- ARIA：<canvas / 装饰元素 aria-hidden 标注>

## 7. 性能预算
- LCP ≤ <2.5s>，CLS ≤ <0.1>，TBT ≤ <300ms>
- bundle gzip ≤ <300KB>（不含 3D 资产）
- 3D 三角面 ≤ <50k>，纹理 ≤ <2K>
- **mobile 降级（必填一行）**：<≤ 768px 时哪些动效 / 3D / 视差关或简化；hero 是否改竖排；写明意图即可，断点细节归下游>。原型仅按 1024+ 桌面演示，完整响应式由下游 team 按目标项目断点系统适配

## 8. 技术栈与依赖
- 框架：<React+Vite / vanilla>
- 动效：<framer-motion / gsap@scroll-trigger>
- 3D：<@react-three/fiber + @react-three/drei / three.js>
- 其他：<列依赖名>

## 9. 验收点
- [ ] <用户需求逐条>
- [ ] 占位资产清单 §5 完整，无硬编码外链
- [ ] §6 可访问性三项实测通过
- [ ] §7 性能预算实测达标
