---
slug: <kebab>
ref_url: <参考站 URL，无则 "无 (从零设计)">
captured_at: <YYYY-MM-DD HH:MM>
playwright: <yes | no (降级到 WebFetch)>
---

# <参考站标题或主题> 拆解

## 技术栈识别
- 框架：<React/Vue/Svelte/none，证据：DOM 标志或 bundle 关键字>
- 动效库：<GSAP/Framer/Motion One/anime.js/none，证据：bundle grep>
- 3D：<Three.js/r3f/Babylon/无，证据：`<canvas>` 数 + bundle grep>
- 后处理/shader：<bloom/SSAO/自研 GLSL/无，证据>

## 资产清单（network 抓取，仅列前 20）
| 类型 | URL | 大小 | 用途推断 |
|---|---|---|---|
| .glb/.gltf | <…> | <…> | <…> |
| .mp4/.webm | <…> | <…> | <…> |
| .ktx2/.basis | <…> | <…> | <…> |
| .hdr | <…> | <…> | <…> |
| 字体 | <…> | <…> | <…> |

## 首屏动效清单
| 元素 | 手法 | 关键参数（实证） | 复刻难度 |
|---|---|---|---|
| <hero 标题> | <CSS/GSAP/Framer> | <duration/easing/触发> | 1-4 |
| <…> | <…> | <…> | <…> |

## 滚动动效清单（仅 Playwright 降级时为"无"）
| 滚动位置 | 元素 | 变化 | 手法 |
|---|---|---|---|
| 0→25% | <…> | <translateY 100→0 / opacity 0→1> | <ScrollTrigger> |

## 交互动效清单（hover / mousemove / click）
| 触发 | 元素 | 变化 | 手法 |
|---|---|---|---|
| hover | <nav 链接> | <下划线展开> | CSS transition |
| mousemove | <hero 卡片> | <transform 跟随> | rAF + transform |

## 复刻难度分级
- 难度 1（CSS 动画）：<列举>
- 难度 2（GSAP / Framer Motion）：<列举>
- 难度 3（Three.js 基础场景）：<列举>
- 难度 4（自研 shader / 复杂粒子 / 角色 GLB）：<列举，给替代方案：占位几何体 / shader-park / drei 现成>

## 资产替代方案（真人/下游提供前的占位）
| 原资产 | 占位方案 |
|---|---|
| <character.glb> | drei `<Icosahedron>` + 渐变材质 |
| <bg-loop.mp4> | CSS 渐变 + canvas 粒子 |
| <portrait.webp 6 张> | 灰色块 + 文字标签或 https://picsum.photos/ 占位 |
| <icon set> | heroicons / lucide / svgrepo 免费 SVG |

## 降级说明（无 Playwright 时填）
- 滚动动效清单为空：未做滚动录帧
- 交互动效仅基于 DOM 静态结构推断，可能漏掉 mousemove 类
- 资产清单仅来自首屏 HTML 的 src/href，未含 lazy load 资产
