extends RefCounted
class_name PatternTextureGenerator

var noise: FastNoiseLite
var default_seed: int = 42

func _init():
    noise = FastNoiseLite.new()
    noise.seed = default_seed
    noise.frequency = 0.1
    noise.fractal_octaves = 2
    noise.fractal_persistence = 0.5

# ========== ГЕНЕРАЦИЯ ТЕКСТУР ==========

func generate_from_pattern(pattern: Dictionary) -> Image:
    """Генерация текстуры из паттерна"""
    var tile_size = pattern.get("tile_size", 16)
    var colors = pattern.get("base_colors", {})
    var noise_params = pattern.get("noise_params", {})
    var rules = pattern.get("rules", [])
    
    # Настройка шума
    noise.seed = noise_params.get("seed", default_seed)
    noise.frequency = 1.0 / noise_params.get("scale", 0.5)
    noise.fractal_octaves = noise_params.get("octaves", 2)
    noise.fractal_persistence = noise_params.get("persistence", 0.5)
    
    # Парсинг цветов
    var primary = Color.html(colors.get("primary", "#808080"))
    var secondary = Color.html(colors.get("secondary", "#404040"))
    var accent = Color.html(colors.get("accent", "#A0A0A0"))
    
    var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
    
    for y in tile_size:
        for x in tile_size:
            var noise_val = noise.get_noise_2d(x, y)
            var color = _mix_colors(primary, secondary, accent, noise_val)
            
            # Применение правил
            color = _apply_rules(color, x, y, tile_size, rules)
            
            img.set_pixel(x, y, color)
    
    return img

func _mix_colors(primary: Color, secondary: Color, accent: Color, noise_val: float) -> Color:
    """Смешивание цветов на основе шума"""
    var t = (noise_val + 1.0) / 2.0  # Нормализация от 0 до 1
    
    if t < 0.33:
        return primary.lerp(secondary, t * 3)
    elif t < 0.66:
        return secondary.lerp(accent, (t - 0.33) * 3)
    else:
        return accent.lerp(primary, (t - 0.66) * 3)

func _apply_rules(color: Color, x: int, y: int, tile_size: int, rules: Array) -> Color:
    """Применение правил к пикселю"""
    for rule in rules:
        var rule_type = rule.get("type", "")
        
        if rule_type == "mosaic":
            var cell_size = rule.get("cell_size", 4)
            var cell_x = floor(x / cell_size) * cell_size
            var cell_y = floor(y / cell_size) * cell_size
            # Небольшая вариация для мозаики
            var variation = rule.get("variation", 0.15)
            color = color.srgb_to_linear()
            color.r += randf_range(-variation, variation)
            color.g += randf_range(-variation, variation)
            color.b += randf_range(-variation, variation)
            color = color.linear_to_srgb()
        
        elif rule_type == "edge_detection":
            var threshold = rule.get("threshold", 0.3)
            var edge_color = Color.html(rule.get("color", "#2D3748"))
            
            # Простая детекция краев
            if x > 0 and x < tile_size - 1 and y > 0 and y < tile_size - 1:
                # Можно расширить логику детекции
                pass
    
    return color.clamped()

# ========== СОХРАНЕНИЕ/ЗАГРУЗКА ПАТТЕРНОВ ==========

func save_pattern(pattern: Dictionary, name: String) -> Error:
    """Сохранение паттерна в JSON"""
    var file = FileAccess.open("res://patterns/%s.json" % name, FileAccess.WRITE)
    if not file:
        return ERR_CANT_CREATE
    
    var json_string = JSON.stringify(pattern, "\t")
    file.store_string(json_string)
    file.close()
    return OK

func load_pattern(name: String) -> Dictionary:
    """Загрузка паттерна из JSON"""
    var file = FileAccess.open("res://patterns/%s.json" % name, FileAccess.READ)
    if not file:
        return {}
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var error = json.parse(json_string)
    if error != OK:
        return {}
    
    return json.data

# ========== СОЗДАНИЕ ДЕФОЛТНЫХ ПАТТЕРНОВ ==========

func create_default_patterns():
    """Создание наборов дефолтных паттернов"""
    var patterns = [
        {
            "pattern_name": "stone_floor",
            "tile_size": 16,
            "base_colors": {
                "primary": "#6B7280",
                "secondary": "#4B5563",
                "accent": "#9CA3AF"
            },
            "noise_params": {
                "scale": 0.8,
                "octaves": 2,
                "persistence": 0.5,
                "seed": 42
            },
            "rules": [
                {"type": "mosaic", "cell_size": 4, "variation": 0.1}
            ]
        },
        {
            "pattern_name": "grass",
            "tile_size": 16,
            "base_colors": {
                "primary": "#4A7C23",
                "secondary": "#2D5016",
                "accent": "#6B9B37"
            },
            "noise_params": {
                "scale": 0.6,
                "octaves": 3,
                "persistence": 0.6,
                "seed": 123
            },
            "rules": []
        },
        {
            "pattern_name": "water",
            "tile_size": 16,
            "base_colors": {
                "primary": "#4A90B8",
                "secondary": "#2E5C7A",
                "accent": "#6BB8D9"
            },
            "noise_params": {
                "scale": 1.0,
                "octaves": 2,
                "persistence": 0.4,
                "seed": 456
            },
            "rules": [
                {"type": "edge_detection", "threshold": 0.3, "color": "#1A3A52"}
            ]
        }
    ]
    
    for pattern in patterns:
        save_pattern(pattern, pattern.pattern_name)
