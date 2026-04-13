extends RefCounted
class_name PatternData

# Структура данных паттерна
var pattern_name: String = ""
var tile_size: int = 16
var base_colors: Dictionary = {}
var noise_params: Dictionary = {}
var rules: Array = []
var animation_params: Dictionary = {}

func _init():
    reset()

func reset():
    pattern_name = "untitled"
    tile_size = 16
    base_colors = {
        "primary": "#808080",
        "secondary": "#404040",
        "accent": "#A0A0A0"
    }
    noise_params = {
        "scale": 0.5,
        "octaves": 2,
        "persistence": 0.5,
        "seed": 42
    }
    rules = []
    animation_params = {}

func to_dict() -> Dictionary:
    return {
        "pattern_name": pattern_name,
        "tile_size": tile_size,
        "base_colors": base_colors,
        "noise_params": noise_params,
        "rules": rules,
        "animation_params": animation_params
    }

func from_dict(data: Dictionary):
    pattern_name = data.get("pattern_name", "untitled")
    tile_size = data.get("tile_size", 16)
    base_colors = data.get("base_colors", base_colors)
    noise_params = data.get("noise_params", noise_params)
    rules = data.get("rules", [])
    animation_params = data.get("animation_params", {})

# ========== ПРЕСЕТЫ ==========

static func create_stone_preset() -> PatternData:
    var data = PatternData.new()
    data.pattern_name = "stone"
    data.base_colors = {
        "primary": "#6B7280",
        "secondary": "#4B5563",
        "accent": "#9CA3AF"
    }
    data.noise_params = {
        "scale": 0.8,
        "octaves": 2,
        "persistence": 0.5,
        "seed": 42
    }
    data.rules = [
        {"type": "mosaic", "cell_size": 4, "variation": 0.1}
    ]
    return data

static func create_grass_preset() -> PatternData:
    var data = PatternData.new()
    data.pattern_name = "grass"
    data.base_colors = {
        "primary": "#4A7C23",
        "secondary": "#2D5016",
        "accent": "#6B9B37"
    }
    data.noise_params = {
        "scale": 0.6,
        "octaves": 3,
        "persistence": 0.6,
        "seed": 123
    }
    return data

static func create_water_preset() -> PatternData:
    var data = PatternData.new()
    data.pattern_name = "water"
    data.base_colors = {
        "primary": "#4A90B8",
        "secondary": "#2E5C7A",
        "accent": "#6BB8D9"
    }
    data.noise_params = {
        "scale": 1.0,
        "octaves": 2,
        "persistence": 0.4,
        "seed": 456
    }
    data.animation_params = {
        "type": "water",
        "frames": 4,
        "fps": 4
    }
    return data

static func create_sand_preset() -> PatternData:
    var data = PatternData.new()
    data.pattern_name = "sand"
    data.base_colors = {
        "primary": "#E6C88A",
        "secondary": "#C9A961",
        "accent": "#F5DEB3"
    }
    data.noise_params = {
        "scale": 0.4,
        "octaves": 3,
        "persistence": 0.7,
        "seed": 789
    }
    return data

static func create_lava_preset() -> PatternData:
    var data = PatternData.new()
    data.pattern_name = "lava"
    data.base_colors = {
        "primary": "#CF3020",
        "secondary": "#8B1A0E",
        "accent": "#FF6B35"
    }
    data.noise_params = {
        "scale": 1.2,
        "octaves": 2,
        "persistence": 0.6,
        "seed": 999
    }
    data.animation_params = {
        "type": "fire",
        "frames": 4,
        "fps": 4
    }
    return data
