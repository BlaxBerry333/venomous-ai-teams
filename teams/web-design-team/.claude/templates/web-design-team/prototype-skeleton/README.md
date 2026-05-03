# Prototype

由 web-design-team 执行者生成。设计稿见 `../design-spec.md`。

## 跑

```bash
npm install
npm run dev
```

打开 http://127.0.0.1:5173/ 。

## 替换占位

设计稿 §5「资产清单」列了所有占位项。每项标注了真品规格 + 替换路径。

## 改主题

设计 token 集中在 `src/global.css` 顶部 `:root`。

## 关动效

页面默认尊重 `prefers-reduced-motion: reduce`。系统级开启后所有 transition / animation 自动降级到 0.01ms。
