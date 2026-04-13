extends RefCounted
class_name AtlasExporter

# Экспорт текстурных атласов и sprite sheets

func export_frames_as_atlas(frames: Array[Image], output_path: String, columns: int = 4) -> Error:
    """Экспорт кадров анимации как атлас (sprite sheet)"""
    if frames.is_empty():
        push_error("No frames to export")
        return ERR_INVALID_DATA
    
    var tile_size = frames[0].get_width()
    var tile_height = frames[0].get_height()
    var total_frames = frames.size()
    
    var rows = ceil(float(total_frames) / columns)
    
    # Создание атласа
    var atlas = Image.create(tile_size * columns, tile_height * rows, false, Image.FORMAT_RGBA8)
    
    for i in range(total_frames):
        var col = i % columns
        var row = floor(float(i) / columns)
        var pos_x = col * tile_size
        var pos_y = row * tile_height
        
        # Копирование кадра на атлас
        atlas.blit_rect(frames[i], Rect2i(0, 0, tile_size, tile_height), Vector2i(pos_x, pos_y))
    
    # Сохранение
    var err = atlas.save_png(output_path)
    if err != OK:
        push_error("Failed to save atlas: " + output_path)
        return err
    
    # Создание metadata
    _save_atlas_metadata(output_path, tile_size, tile_height, columns, rows, total_frames)
    
    return OK

func _save_atlas_metadata(atlas_path: String, tile_width: int, tile_height: int, columns: int, rows: int, total_frames: int):
    """Сохранение metadata для атласа"""
    var metadata = {
        "tile_width": tile_width,
        "tile_height": tile_height,
        "columns": columns,
        "rows": rows,
        "total_frames": total_frames,
        "frame_duration": 0.25,
        "fps": 4,
        "animation_type": "sequence"
    }
    
    var metadata_path = atlas_path.replace(".png", ".json")
    var file = FileAccess.open(metadata_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(metadata, "\t"))
        file.close()

func create_texture_atlas(patterns: Array[Dictionary], output_path: String, tile_size: int) -> Error:
    """Создание атласа из нескольких паттернов"""
    var generator = PatternTextureGenerator.new()
    var images: Array[Image] = []
    
    for pattern in patterns:
        var img = generator.generate_from_pattern(pattern)
        
        # Ресайз к единому размеру если нужно
        if img.get_width() != tile_size or img.get_height() != tile_size:
            img.resize(tile_size, tile_size)
        
        images.append(img)
    
    return export_frames_as_atlas(images, output_path, ceil(sqrt(images.size())))

func export_with_mipmaps(image: Image, output_path: String, max_mipmap_level: int = 4) -> Error:
    """Экспорт с генерацией мипмапов"""
    # Godot Image не поддерживает прямую экспортизацию мипмапов в PNG
    # Мипмапы генерируются при импорте в Godot
    push_warning("Mipmaps are generated at import time in Godot, not during PNG export")
    return image.save_png(output_path)

func create_seamless_tile(pattern: Dictionary, tile_size: int) -> Image:
    """Создание бесшовного тайла"""
    var generator = PatternTextureGenerator.new()
    var img = generator.generate_from_pattern(pattern)
    
    # Применение blending для краев
    _blend_edges(img, tile_size)
    
    return img

func _blend_edges(img: Image, tile_size: int):
    """Blend краев для создания бесшовного тайла"""
    var blend_width = 2
    
    for y in range(blend_width):
        for x in tile_size:
            # Top edge blending
            var top_color = img.get_pixel(x, y)
            var bottom_color = img.get_pixel(x, tile_size - 1 - y)
            var blended = top_color.lerp(bottom_color, float(y) / blend_width)
            img.set_pixel(x, y, blended)
            img.set_pixel(x, tile_size - 1 - y, blended)
            
            # Left edge blending
            var left_color = img.get_pixel(y, x)
            var right_color = img.get_pixel(tile_size - 1 - y, x)
            blended = left_color.lerp(right_color, float(y) / blend_width)
            img.set_pixel(y, x, blended)
            img.set_pixel(tile_size - 1 - y, x, blended)

func generate_variation_set(pattern: Dictionary, count: int, output_dir: String) -> Error:
    """Генерация набора вариаций паттерна"""
    var generator = PatternTextureGenerator.new()
    var base_seed = pattern.get("noise_params", {}).get("seed", 42)
    
    for i in range(count):
        var modified = pattern.duplicate(true)
        modified.noise_params.seed = base_seed + i * 1000
        
        # Небольшие вариации цветов
        if "base_colors" in modified:
            for color_key in modified.base_colors:
                var color = Color.html(modified.base_colors[color_key])
                var variation = randf_range(-0.1, 0.1)
                color.h += variation
                modified.base_colors[color_key] = color.to_html()
        
        var img = generator.generate_from_pattern(modified)
        var path = "%s/%s_var_%03d.png" % [output_dir, pattern.pattern_name, i]
        img.save_png(path)
    
    return OK
