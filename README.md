# 🎨 Pattern Generator for Godot 4.6.2

[![Godot Engine](https://img.shields.io/badge/Godot-4.6.2-%23478cbf?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A complete procedural texture and animation generation toolkit for Godot Engine 4.6.2. Includes a GUI editor, animation system, and exporters for tilesets and atlases.

---

## 📁 Project Structure

```
res://
├── addons/
│   └── pattern_generator/
│       ├── pattern_generator.gd (autoload)
│       ├── plugin.cfg
│       ├── gui/
│       │   ├── pattern_editor.tscn
│       │   └── pattern_editor.gd
│       ├── core/
│       │   ├── texture_generator.gd
│       │   ├── animation_generator.gd
│       │   └── pattern_data.gd
│       └── export/
│           ├── tileset_exporter.gd
│           └── atlas_exporter.gd
├── patterns/ (JSON pattern files)
├── textures/
│   ├── generated/ (static textures)
│   └── animated/ (animated textures)
└── tilesets/ (exported tilesets)
```

---

## ✨ Features

### 🖥️ GUI Pattern Editor
- Color picker (primary, secondary, accent)
- Noise settings (scale, octaves, persistence, seed)
- Generation rules (mosaic effect, edge detection)
- Real-time preview
- Save/load patterns as JSON
- Export to PNG

### 🎨 Texture Generator
- FastNoiseLite-based generation
- Perlin noise color blending
- Rule application (mosaic, edge detection)
- Default presets (stone, grass, water, sand, wood)

### 🎬 Animation Generator
- **Water** - waves with highlights
- **Grass** - swaying grass
- **Fire** - fire with smoke
- Export to AnimatedTexture

### 📦 Exporters
- **TileSet Exporter** - Export to Godot TileSet format
- **Atlas Exporter** - Create sprite sheets and texture atlases

### ⚡ Autoload Manager
Quick access methods for common operations.

---

## 📖 Installation

1. Copy the `addons/pattern_generator` folder to your project
2. Enable the plugin in Project Settings → Plugins
3. Add `pattern_generator.gd` as autoload (Project Settings → Autoload)
4. Create directories: `patterns/`, `textures/generated/`, `textures/animated/`, `tilesets/`

---

## 🚀 Quick Start

### Generate a Texture
```gdscript
var generator = PatternTextureGenerator.new()

# Create default patterns
generator.create_default_patterns()

# Load a pattern
var pattern = generator.load_pattern("stone")

# Generate texture
var image = generator.generate_from_pattern(pattern)
var texture = ImageTexture.create_from_image(image)
```

### Create an Animation
```gdscript
var generator = PatternTextureGenerator.new()
var animator = AnimationTextureGenerator.new(generator)

# Generate water animation
var frames = animator.generate_water_animation(16, 4)
var animated_texture = animator.create_animated_texture_from_frames(frames)

# Assign to Sprite2D
$Sprite2D.texture = animated_texture
```

### Open the GUI Editor
```gdscript
var editor = preload("res://addons/pattern_generator/gui/pattern_editor.tscn").instantiate()
add_child(editor)
```

---

## 📝 Pattern JSON Format

```json
{
    "pattern_name": "custom_stone",
    "tile_size": 16,
    "base_colors": {
        "primary": "#808080",
        "secondary": "#404040",
        "accent": "#A0A0A0"
    },
    "noise_params": {
        "scale": 0.8,
        "octaves": 2,
        "persistence": 0.5,
        "seed": 42
    },
    "rules": [
        {
            "type": "mosaic",
            "cell_size": 4,
            "variation": 0.15
        },
        {
            "type": "edge_detection",
            "threshold": 0.3,
            "color": "#2D3748"
        }
    ]
}
```

---

## 📊 Noise Parameters

| Parameter | Description | Range | Default |
|-----------|-------------|-------|---------|
| scale | Noise scale | 0.1 - 3.0 | 0.8 |
| octaves | Number of octaves | 1 - 6 | 2 |
| persistence | Persistence | 0.1 - 1.0 | 0.5 |
| seed | Random seed | any | randi() |

---

## 🛠️ Rules

| Rule | Description | Parameters |
|------|-------------|------------|
| mosaic | Mosaic effect | cell_size, variation |
| edge_detection | Edge detection | threshold, color |

---

## 💡 Examples

### Batch Generate Textures
```gdscript
var generator = PatternTextureGenerator.new()
var patterns = ["stone", "grass", "water", "sand"]

for pattern_name in patterns:
    var pattern = generator.load_pattern(pattern_name)
    var img = generator.generate_from_pattern(pattern)
    img.save_png("res://textures/generated/%s.png" % pattern_name)
```

### Export TileSet
```gdscript
var exporter = TileSetExporter.new()
var generator = PatternTextureGenerator.new()

var patterns = ["stone", "grass", "water"]
var images = []

for name in patterns:
    var pattern = generator.load_pattern(name)
    images.append(generator.generate_from_pattern(pattern))

var tileset = exporter.export_tileset_from_images(images, 16)
ResourceSaver.save(tileset, "res://tilesets/terrain.tres")
```

### Create Animated Water Sprite
```gdscript
var generator = PatternTextureGenerator.new()
var animator = AnimationTextureGenerator.new(generator)

var frames = animator.generate_water_animation(32, 8)
animator.save_animated_texture(frames, "res://textures/animated/water.png", 12)

# Load the AnimatedTexture
var anim_texture = load("res://textures/animated/water.tres")
$WaterSprite.texture = anim_texture
```

---

## 🔧 Extending

### Add a New Rule
```gdscript
func apply_blur_rule(img: Image, amount: int = 2) -> Image:
    """Apply blur effect"""
    var blurred = img.duplicate()
    for y in range(img.get_height()):
        for x in range(img.get_width()):
            var color = Color.BLACK
            var count = 0
            for dy in range(-amount, amount + 1):
                for dx in range(-amount, amount + 1):
                    var nx = clamp(x + dx, 0, img.get_width() - 1)
                    var ny = clamp(y + dy, 0, img.get_height() - 1)
                    color += img.get_pixel(nx, ny)
                    count += 1
            blurred.set_pixel(x, y, color / count)
    return blurred
```

### Add a New Animation
```gdscript
func generate_lava_animation(tile_size: int = 16, frames: int = 4) -> Array[Image]:
    """Lava animation"""
    var frames_array: Array[Image] = []
    
    for i in range(frames):
        var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
        
        for y in tile_size:
            for x in tile_size:
                var noise_val = generator.noise.get_noise_2d(x + i * 2, y - i * 3)
                
                var lava_core = Color(1.0, 0.3, 0.0)
                var lava_edge = Color(0.5, 0.0, 0.0)
                
                var intensity = (noise_val + 1.0) / 2.0
                var color = lava_edge.lerp(lava_core, intensity)
                
                img.set_pixel(x, y, color)
        
        frames_array.append(img)
    
    return frames_array
```

---

## 📄 License

MIT License - feel free to use in your projects.

---

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

## 🙏 Credits

Created for Godot Engine 4.6.2 community.

Made with ❤️ using FastNoiseLite for procedural generation.  
