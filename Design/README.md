# ZRightClick 应用图标

`AppIcon-master.png` 是生成的透明背景原图。应用使用 `ZRightClickApp/Assets.xcassets/AppIcon.appiconset` 中的 macOS 16–1024 px 图标，Debug 和 Release 都配置为 `AppIcon`。菜单栏保留适配系统深浅色的单色模板符号。

生成方式：内置 image_gen 工具。各尺寸由 macOS `sips` 缩放生成，不修改图标设计。

## 生成提示词

```text
Use case: logo-brand
Asset type: production macOS app icon for ZRightClick, a Finder context-menu utility.
Primary request: a minimal, sophisticated, instantly legible icon that combines one crisp mouse cursor arrow with a small three-line context menu.
Design: one centered macOS rounded-square tile in deep midnight navy, subtly luminous edge, restrained soft blue depth. Within the tile, a bright ivory cursor arrow overlaps the lower-left of a small rounded context-menu panel outlined in soft icy blue, with exactly three short horizontal lines, one accent line in vivid periwinkle blue. Strong simple silhouette, generous breathing room, very few shapes, exquisitely balanced proportions. Premium quiet utility aesthetic, clean vector-like precision with only subtle material depth, sharp readable at 16px.
Composition: square 1024x1024 canvas, front view perfectly straight, icon tile occupies about 82% of canvas width, centered with equal transparent outer margins; outer corners smoothly rounded in macOS style. A very subtle tight shadow beneath the tile. Alpha transparency outside tile.
Text: none.
Avoid: letters, wordmarks, Z monogram, photos, mockup scenes, extra icons, sparkles, decorative details, dramatic 3D perspective, glass clutter, watermark. Output only the single finished app icon.
```
