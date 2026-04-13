extends RefCounted
class_name TilesetExporter

# Экспорт в Godot TileSet формат

func export_as_tileset(image: Image, tile_size: int, output_path: String) -> Error:
    """Экспорт текстуры как тайлсета"""
    var img_width = image.get_width()
    var img_height = image.get_height()
    
    if img_width % tile_size != 0 or img_height % tile_size != 0:
        push_error("Image dimensions must be divisible by tile size")
        return ERR_INVALID_DATA
    
    # Создаем новую текстуру с тайлами
    var tiles_x = img_width / tile_size
    var tiles_y = img_height / tile_size
    
    # Сохраняем как есть для использования в TileSet
    var err = image.save_png(output_path)
    if err != OK:
        push_error("Failed to save tileset: " + output_path)
        return err
    
    # Создаем metadata файл
    var metadata = {
        "tile_size": tile_size,
        "tiles_x": tiles_x,
        "tiles_y": tiles_y,
        "total_tiles": tiles_x * tiles_y,
        "source_image": output_path
    }
    
    var metadata_path = output_path.replace(".png", ".json")
    var file = FileAccess.open(metadata_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(metadata, "\t"))
        file.close()
    
    return OK

func create_terrain_set(pattern_data: Dictionary, output_dir: String) -> Error:
    """Создание набора terrain тайлов"""
    var generator = PatternTextureGenerator.new()
    
    # Генерация вариаций для terrain
    var variations = ["center", "corner", "edge", "transition"]
    var base_seed = pattern_data.get("noise_params", {}).get("seed", 42)
    
    for variation in variations:
        var modified_pattern = pattern_data.duplicate(true)
        modified_pattern.noise_params.seed = base_seed + hash(variation)
        
        # Применение специфичных модификаций
        _apply_terrain_modification(modified_pattern, variation)
        
        var img = generator.generate_from_pattern(modified_pattern)
        var path = "%s/%s_%s.png" % [output_dir, pattern_data.pattern_name, variation]
        img.save_png(path)
    
    return OK

func _apply_terrain_modification(pattern: Dictionary, variation: String):
    """Применение модификаций для terrain типа"""
    if variation == "corner":
        # Увеличение контраста для углов
        var colors = pattern.base_colors
        colors.primary = _darken_color(colors.primary, 0.2)
        colors.secondary = _lighten_color(colors.secondary, 0.1)
    elif variation == "edge":
        # Добавление градиента
        pattern.rules.append({
            "type": "edge_detection",
            "threshold": 0.4,
            "color": "#1A1A1A"
        })
    elif variation == "transition":
        # Смешивание цветов для перехода
        var colors = pattern.base_colors
        colors.accent = Color.html(colors.primary).lerp(Color.html(colors.secondary), 0.5).to_html()

func _darken_color(hex_color: String, amount: float) -> String:
    var color = Color.html(hex_color)
    color = color.darkened(amount)
    return color.to_html()

func _lighten_color(hex_color: String, amount: float) -> String:
    var color = Color.html(hex_color)
    color = color.lightened(amount)
    return color.to_html()

# ========== АТЛАС ЭКСПОРТ ==========

func export_as_atlas(images: Array[Image], output_path: String, columns: int = 4) -> Error:
    """Экспорт массива изображений как атлас"""
    if images.is_empty():
        return ERR_INVALID_DATA
    
    var tile_size = images[0].get_width()
    var rows = ceil(float(images.size()) / columns)
    
    var atlas = Image.create(tile_size * columns, tile_size * rows, false, Image.FORMAT_RGBA8)
    
    for i in range(images.size()):
        var col = i % columns
        var row = floor(float(i) / columns)
        atlas.blit_rect(images[i], Rect2i(0, 0, tile_size, tile_size), Vector2i(col * tile_size, row * tile_size))
    
    return atlas.save_png(output_path)

func create_sprite_sheet(frames: Array[Image], output_path: String) -> Error:
    """Создание sprite sheet из кадров анимации"""
    return export_as_atlas(frames, output_path, frames.size())
