# 🎨 Pattern Generator для Godot 4.6.2

## Описание

Полный пакет для генерации процедурных текстур и анимаций в Godot Engine 4.6.2. Включает GUI редактор, систему анимаций и экспортёры для тайлсетов и атласов.

---

## 📁 Структура проекта

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
├── patterns/ (JSON файлы паттернов)
├── textures/
│   ├── generated/ (статические текстуры)
│   └── animated/ (анимированные текстуры)
└── tilesets/ (экспортированные тайлсеты)
```

---

## 🚀 Возможности

### 1️⃣ GUI Редактор паттернов

**Интерфейс включает:**
- Выбор цветов (primary, secondary, accent)
- Настройки шума (scale, octaves, persistence, seed)
- Правила генерации (mosaic effect, edge detection)
- Предпросмотр в реальном времени
- Сохранение/загрузка паттернов в JSON
- Экспорт в PNG

**Использование:**
```gdscript
# Открыть редактор
var editor = preload("res://addons/pattern_generator/gui/pattern_editor.tscn").instantiate()
add_child(editor)
```

### 2️⃣ Генератор текстур

**Функции:**
- Генерация на основе FastNoiseLite
- Смешивание цветов через шум Перлина
- Применение правил (мозаика, детекция краев)
- Создание дефолтных пресетов (stone, grass, water, sand, wood)

**Пример использования:**
```gdscript
var generator = PatternTextureGenerator.new()

# Создать дефолтные паттерны
generator.create_default_patterns()

# Загрузить паттерн
var pattern = generator.load_pattern("stone")

# Сгенерировать текстуру
var image = generator.generate_from_pattern(pattern)
var texture = ImageTexture.create_from_image(image)

# Сохранить
generator.save_pattern(pattern, "my_custom_stone")
```

### 3️⃣ Генератор анимаций

**Поддерживаемые анимации:**
- **Water** - волны с бликами
- **Grass** - колышущаяся трава
- **Fire** - огонь с дымом

**Пример использования:**
```gdscript
var animator = AnimationTextureGenerator.new(generator)

# Анимация воды
var water_frames = animator.generate_water_animation(16, 4)
var water_texture = animator.create_animated_texture_from_frames(water_frames)

# Анимация травы
var grass_frames = animator.generate_grass_animation(16, 4)

# Анимация огня
var fire_frames = animator.generate_fire_animation(16, 4)

# Сохранение анимации
animator.save_animated_texture(grass_frames, "res://textures/animated/grass.png", 12)
```

### 4️⃣ Экспортёры

#### TileSet Exporter
```gdscript
var exporter = TileSetExporter.new()

# Экспорт в формат TileSet
var tileset = exporter.export_tileset(patterns_array, 16)
ResourceSaver.save(tileset, "res://tilesets/my_tileset.tres")

# Создание тайлов из директории
var tiles = exporter.create_tiles_from_directory("res://textures/generated/")
```

#### Atlas Exporter
```gdscript
var atlas = AtlasExporter.new()

# Создание sprite sheet
var sprite_sheet = atlas.create_sprite_sheet(textures_array, 4, 4)
sprite_sheet.save_png("res://textures/atlas.png")

# Создание TextureAtlas
var texture_atlas = atlas.create_texture_atlas(textures_array)
```

### 5️⃣ Autoload менеджер

**Быстрые методы:**
```gdscript
# Генерация одиночной текстуры
var texture = PatternGenerator.generate_texture("stone", 16)

# Генерация анимации
var anim = PatternGenerator.generate_animation("water", 16, 4)

# Применение к TileMap
PatternGenerator.apply_to_tilemap(my_tilemap, "grass", Vector2i(0, 0))

# Массовая генерация
PatternGenerator.batch_generate(["stone", "grass", "water"], 16)
```

---

## 📖 Установка

1. Скопируйте папку `addons/pattern_generator` в ваш проект
2. Включите плагин в Project Settings → Plugins
3. Добавьте `pattern_generator.gd` как autoload (Project Settings → Autoload)
4. Создайте директории: `patterns/`, `textures/generated/`, `textures/animated/`, `tilesets/`

---

## 🎯 Примеры использования

### Быстрая генерация текстуры
```gdscript
var img = PatternGenerator.generate_single_texture(
    Color(0.5, 0.5, 0.5),  # primary
    Color(0.3, 0.3, 0.3),  # secondary
    Color(0.7, 0.7, 0.7),  # accent
    16,                    # tile_size
    42                     # seed
)
var texture = ImageTexture.create_from_image(img)
```

### Создание анимированного спрайта
```gdscript
var generator = PatternTextureGenerator.new()
var animator = AnimationTextureGenerator.new(generator)

var pattern = {
    "tile_size": 16,
    "base_colors": {
        "primary": "#4A90E2",
        "secondary": "#2D5A8C",
        "accent": "#7BB3E8"
    },
    "noise_params": {
        "scale": 0.8,
        "octaves": 2,
        "persistence": 0.5,
        "seed": 12345
    }
}

var frames = animator.generate_water_animation(16, 4)
var animated_texture = animator.create_animated_texture_from_frames(frames)

# Назначить на Sprite2D
$Sprite2D.texture = animated_texture
```

### Экспорт тайлсета
```gdscript
var exporter = TileSetExporter.new()
var generator = PatternTextureGenerator.new()

var patterns = ["stone", "grass", "water", "sand"]
var textures = []

for pattern_name in patterns:
    var pattern = generator.load_pattern(pattern_name)
    var img = generator.generate_from_pattern(pattern)
    textures.append(img)

var tileset = exporter.export_tileset_from_images(textures, 16)
ResourceSaver.save(tileset, "res://tilesets/terrain.tres")
```

---

## ⚙️ Настройки паттерна

### Базовая структура JSON
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

### Параметры шума
| Параметр | Описание | Диапазон | По умолчанию |
|----------|----------|----------|--------------|
| scale | Масштаб шума | 0.1 - 3.0 | 0.8 |
| octaves | Количество октав | 1 - 6 | 2 |
| persistence | Персистентность | 0.1 - 1.0 | 0.5 |
| seed | Случайное зерно | любое | randi() |

### Правила
| Правило | Описание | Параметры |
|---------|----------|-----------|
| mosaic | Эффект мозаики | cell_size, variation |
| edge_detection | Детекция краев | threshold, color |

---

## 🔧 Расширение

### Добавление нового правила
```gdscript
func apply_blur_rule(img: Image, amount: int = 2):
    """Размытие изображения"""
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

### Добавление новой анимации
```gdscript
func generate_lava_animation(tile_size: int = 16, frames: int = 4) -> Array[Image]:
    """Анимация лавы"""
    var frames_array: Array[Image] = []
    
    for i in range(frames):
        var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
        
        for y in tile_size:
            for x in tile_size:
                var noise_val = generator.noise.get_noise_2d(x + i * 2, y - i * 3)
                
                # Цвета лавы
                var lava_core = Color(1.0, 0.3, 0.0)
                var lava_edge = Color(0.5, 0.0, 0.0)
                
                var intensity = (noise_val + 1.0) / 2.0
                var color = lava_edge.lerp(lava_core, intensity)
                
                img.set_pixel(x, y, color)
        
        frames_array.append(img)
    
    return frames_array
```

---

## 📝 Лицензия

MIT License - свободно используйте в своих проектах.

---

## 🤝 Поддержка

Для вопросов и предложений создавайте issues на GitHub.
