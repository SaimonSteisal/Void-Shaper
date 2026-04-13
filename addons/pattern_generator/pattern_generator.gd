extends EditorPlugin

## Pattern Generator Autoload
## Центральный менеджер для генерации паттернов, анимаций и экспорта

var texture_generator: PatternTextureGenerator
var animation_generator: AnimationTextureGenerator
var tileset_exporter: TilesetExporter
var atlas_exporter: AtlasExporter

# Пути к скриптам
const TEXTURE_GENERATOR_SCRIPT = preload("res://addons/pattern_generator/core/texture_generator.gd")
const ANIMATION_GENERATOR_SCRIPT = preload("res://addons/pattern_generator/core/animation_generator.gd")
const TILESET_EXPORTER_SCRIPT = preload("res://addons/pattern_generator/export/tileset_exporter.gd")
const ATLAS_EXPORTER_SCRIPT = preload("res://addons/pattern_generator/export/atlas_exporter.gd")

func _enter_tree():
	_initialize_generators()

func _exit_tree():
	# Очистка при отключении плагина
	texture_generator = null
	animation_generator = null
	tileset_exporter = null
	atlas_exporter = null

func _initialize_generators():
	"""Инициализация всех генераторов"""
	texture_generator = TEXTURE_GENERATOR_SCRIPT.new()
	animation_generator = ANIMATION_GENERATOR_SCRIPT.new(texture_generator)
	tileset_exporter = TILESET_EXPORTER_SCRIPT.new()
	atlas_exporter = ATLAS_EXPORTER_SCRIPT.new()

# ========== БЫСТРЫЕ МЕТОДЫ ГЕНЕРАЦИИ ==========

func generate_texture(pattern_name: String) -> Image:
	"""Быстрая генерация текстуры по имени паттерна"""
	var pattern = texture_generator.load_pattern(pattern_name)
	if pattern.is_empty():
	    push_error("Pattern not found: " + pattern_name)
	    return null
	return texture_generator.generate_from_pattern(pattern)

func generate_animated_texture(pattern_name: String, frames: int = 4) -> Array[Image]:
	"""Генерация анимированной текстуры"""
	var pattern = texture_generator.load_pattern(pattern_name)
	if pattern.is_empty():
	    push_error("Pattern not found: " + pattern_name)
	    return []
	
	# Проверка на наличие animation_params
	if "animation_params" in pattern:
	    var anim_type = pattern.animation_params.get("type", "")
	    if anim_type == "water":
	        return animation_generator.generate_water_animation(pattern.tile_size, frames)
	    elif anim_type == "fire":
	        return animation_generator.generate_fire_animation(pattern.tile_size, frames)
	
	return animation_generator.generate_animated_texture(pattern, frames)

func export_texture(pattern_name: String, output_path: String) -> Error:
	"""Экспорт статической текстуры"""
	var img = generate_texture(pattern_name)
	if not img:
	    return ERR_CANT_CREATE
	return img.save_png(output_path)

func export_animation(pattern_name: String, output_path: String, frames: int = 4) -> Error:
	"""Экспорт анимации как sprite sheet"""
	var frame_images = generate_animated_texture(pattern_name, frames)
	if frame_images.is_empty():
	    return ERR_CANT_CREATE
	return atlas_exporter.export_frames_as_atlas(frame_images, output_path, frames)

# ========== ПРЕСЕТЫ ==========

func create_default_patterns():
	"""Создание дефолтных паттернов"""
	texture_generator.create_default_patterns()

func load_all_patterns() -> Array[String]:
	"""Загрузка списка всех паттернов"""
	var patterns: Array[String] = []
	var dir = DirAccess.open("res://patterns/")
	if dir:
	    dir.list_dir_begin()
	    var file_name = dir.get_next()
	    while file_name != "":
	        if file_name.ends_with(".json"):
	            patterns.append(file_name.replace(".json", ""))
	        file_name = dir.get_next()
	return patterns

# ========== УТИЛИТЫ ==========

func get_pattern_data(pattern_name: String) -> Dictionary:
	"""Получение данных паттерна"""
	return texture_generator.load_pattern(pattern_name)

func save_pattern_data(pattern: Dictionary, name: String) -> Error:
	"""Сохранение данных паттерна"""
	return texture_generator.save_pattern(pattern, name)

func preview_texture(pattern: Dictionary) -> Texture2D:
	"""Создание превью текстуры"""
	var img = texture_generator.generate_from_pattern(pattern)
	return ImageTexture.create_from_image(img)

func preview_animation(pattern: Dictionary, frames: int = 4) -> AnimatedTexture:
	"""Создание превью анимации"""
	var frame_images = animation_generator.generate_animated_texture(pattern, frames)
	return animation_generator.create_animated_texture_from_frames(frame_images)

# ========== ИНТЕГРАЦИЯ С TILEMAP ==========

func create_tileset_resource(pattern_name: String, tile_size: int) -> TileSet:
	"""Создание TileSet ресурса из паттерна"""
	var img = generate_texture(pattern_name)
	if not img:
	    return null
	
	var tileset = TileSet.new()
	var source = TileSetAtlasSource.new()
	
	var texture = ImageTexture.create_from_image(img)
	source.texture = texture
	source.tile_size = Vector2i(tile_size, tile_size)
	
	# Добавление тайлов
	var tiles_x = img.get_width() / tile_size
	var tiles_y = img.get_height() / tile_size
	
	for y in tiles_y:
	    for x in tiles_x:
	        var id = y * tiles_x + x
	        source.create_tile(Vector2i(x, y))
	
	tileset.add_source(source)
	return tileset

# ========== DEBUG ==========

func print_debug_info():
	"""Вывод отладочной информации"""
	print("=== Pattern Generator Debug Info ===")
	print("Texture Generator: ", "OK" if texture_generator else "NULL")
	print("Animation Generator: ", "OK" if animation_generator else "NULL")
	print("Tileset Exporter: ", "OK" if tileset_exporter else "NULL")
	print("Atlas Exporter: ", "OK" if atlas_exporter else "NULL")
	
	var patterns = load_all_patterns()
	print("Loaded patterns: ", patterns.size())
	for p in patterns:
	    print("  - ", p)
