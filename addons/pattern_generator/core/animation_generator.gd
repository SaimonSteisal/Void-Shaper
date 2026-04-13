extends RefCounted
class_name AnimationTextureGenerator

var generator: PatternTextureGenerator

func _init(p_generator: PatternTextureGenerator):
    generator = p_generator

# ========== ГЕНЕРАЦИЯ АНИМИРОВАННЫХ ТЕКСТУР ==========

func generate_animated_texture(pattern: Dictionary, frames: int = 4) -> Array[Image]:
    """Генерация кадров анимации"""
    var frame_images: Array[Image] = []
    var base_seed = pattern.get("noise_params", {}).get("seed", randi())
    
    for i in range(frames):
        # Модификация seed для каждого кадра
        pattern.noise_params.seed = base_seed + i * 1000
        
        # Добавление временной вариации
        if not "animation_params" in pattern:
            pattern.animation_params = {}
        
        pattern.animation_params.frame = i
        pattern.animation_params.total_frames = frames
        
        var frame = generator.generate_from_pattern(pattern)
        frame_images.append(frame)
    
    return frame_images

func generate_water_animation(tile_size: int = 16, frames: int = 4) -> Array[Image]:
    """Специальная анимация воды"""
    var frames_array: Array[Image] = []
    
    for i in range(frames):
        var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
        
        for y in tile_size:
            for x in tile_size:
                # Базовый цвет воды
                var base_color = Color(0.3, 0.5, 0.7)
                
                # Волны через синус
                var wave = sin((x + i * 2) * 0.5 + y * 0.3) * 0.1
                var wave2 = cos((y + i * 3) * 0.4 + x * 0.2) * 0.05
                
                # Шум
                var noise_val = generator.noise.get_noise_2d(x + i * 4, y)
                
                var color = base_color
                color.r += wave + noise_val * 0.1
                color.g += wave2 + noise_val * 0.05
                color.b += 0.1
                
                # Блики
                if noise_val > 0.7:
                    color = color.lerp(Color(0.6, 0.8, 0.9), 0.3)
                
                img.set_pixel(x, y, color)
        
        frames_array.append(img)
    
    return frames_array

func generate_grass_animation(tile_size: int = 16, frames: int = 4) -> Array[Image]:
    """Анимация травы (колыхание)"""
    var frames_array: Array[Image] = []
    var base_seed = generator.noise.seed
    
    for i in range(frames):
        var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
        generator.noise.seed = base_seed + i * 500
        
        for y in tile_size:
            for x in tile_size:
                var noise_val = generator.noise.get_noise_2d(x, y + i * 2)
                
                # Базовые цвета травы
                var grass_dark = Color(0.2, 0.4, 0.1)
                var grass_light = Color(0.3, 0.55, 0.15)
                var grass_accent = Color(0.4, 0.65, 0.2)
                
                # Смешивание на основе шума
                var t = (noise_val + 1.0) / 2.0
                var color: Color
                
                if t < 0.5:
                    color = grass_dark.lerp(grass_light, t * 2)
                else:
                    color = grass_light.lerp(grass_accent, (t - 0.5) * 2)
                
                # Добавление "ветра" - сдвиг по X
                var wind_offset = sin(i * 0.5 + y * 0.3) * 0.05
                var wind_noise = generator.noise.get_noise_2d(x + wind_offset * 10, y)
                color = color.lerp(grass_accent, wind_noise * 0.1)
                
                img.set_pixel(x, y, color)
        
        frames_array.append(img)
    
    generator.noise.seed = base_seed
    return frames_array

func generate_fire_animation(tile_size: int = 16, frames: int = 4) -> Array[Image]:
    """Анимация огня"""
    var frames_array: Array[Image] = []
    
    for i in range(frames):
        var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
        
        for y in tile_size:
            for x in tile_size:
                # Огонь поднимается вверх
                var time_offset = i * 0.5
                var noise_val = generator.noise.get_noise_2d(x * 0.5 + time_offset, y * 0.5 - time_offset * 2)
                
                # Градиент огня (снизу ярче)
                var height_factor = 1.0 - (float(y) / tile_size)
                
                # Цвета огня
                var fire_core = Color(1.0, 0.9, 0.3)  # Желтый центр
                var fire_mid = Color(1.0, 0.5, 0.1)   # Оранжевый
                var fire_edge = Color(0.8, 0.2, 0.1)  # Красный край
                var smoke = Color(0.3, 0.3, 0.3)      # Дым
                
                var color: Color
                var intensity = (noise_val + 1.0) / 2.0 * height_factor
                
                if intensity > 0.7:
                    color = fire_core.lerp(fire_mid, (intensity - 0.7) * 3.3)
                elif intensity > 0.4:
                    color = fire_mid.lerp(fire_edge, (intensity - 0.4) * 3.3)
                elif intensity > 0.2:
                    color = fire_edge.lerp(smoke, (intensity - 0.2) * 5)
                else:
                    color = smoke
                
                # Альфа-канал для прозрачности дыма
                var alpha = clamp(intensity * 1.5, 0.3, 1.0)
                img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
        
        frames_array.append(img)
    
    return frames_array

# ========== СОХРАНЕНИЕ АНИМАЦИЙ ==========

func save_animation_as_gif(frames: Array[Image], path: String, fps: int = 4):
    """Сохранение анимации как GIF (требует GDExtension или плагин)"""
    push_warning("GIF export requires additional plugin. Saving frames as PNG sequence instead.")
    save_animation_sequence(frames, path)

func save_animation_sequence(frames: Array[Image], base_path: String):
    """Сохранение кадров как последовательность PNG"""
    for i in range(frames.size()):
        var frame_path = "%s_frame_%03d.png" % [base_path, i]
        frames[i].save_png(frame_path)

func create_animated_texture_from_frames(frames: Array[Image]) -> AnimatedTexture:
    """Создание AnimatedTexture из кадров"""
    var animated_texture = AnimatedTexture.new()
    animated_texture.frames = frames.size()
    
    for i in range(frames.size()):
        var texture = ImageTexture.create_from_image(frames[i])
        animated_texture.set_frame_texture(i, texture)
        animated_texture.set_frame_duration(i, 0.25)  # 4 FPS
    
    return animated_texture

# ========== ЭКСПОРТ АНИМАЦИЙ ==========

func save_animated_texture(frames: Array[Image], output_path: String, fps: int = 12) -> Error:
    """Сохранение анимации как серии PNG файлов"""
    var dir = DirAccess.open("res://textures/animated/")
    if not dir:
        DirAccess.make_dir_recursive_absolute("res://textures/animated/")
    
    var base_name = output_path.get_file().get_basename()
    
    for i in range(frames.size()):
        var frame_path = "res://textures/animated/%s_frame_%03d.png" % [base_name, i]
        var err = frames[i].save_png(frame_path)
        if err != OK:
            push_error("Failed to save frame %d: %s" % [i, frame_path])
            return err
    
    # Создание ресурса AnimatedTexture
    var animated_texture = AnimatedTexture.new()
    animated_texture.frames = frames.size()
    animated_texture.fps = fps
    
    for i in range(frames.size()):
        var frame_img = frames[i]
        var frame_texture = ImageTexture.create_from_image(frame_img)
        animated_texture.set_frame_texture(i, frame_texture)
        animated_texture.set_frame_duration(i, 1.0 / fps)
    
    var resource_path = output_path.replace(".png", ".tres")
    var save_err = ResourceSaver.save(animated_texture, resource_path)
    
    print("Animated texture saved: ", resource_path)
    return save_err

func create_animated_sprite(pattern: Dictionary, output_name: String, frames: int = 4, fps: int = 12) -> AnimatedTexture:
    """Создание AnimatedTexture из паттерна"""
    var frame_images = generate_animated_texture(pattern, frames)
    var output_path = "res://textures/animated/%s.png" % output_name
    save_animated_texture(frame_images, output_path, fps)
    
    var animated_texture = AnimatedTexture.new()
    animated_texture.frames = frames
    animated_texture.fps = fps
    
    for i in range(frames):
        var frame_texture = ImageTexture.create_from_image(frame_images[i])
        animated_texture.set_frame_texture(i, frame_texture)
        animated_texture.set_frame_duration(i, 1.0 / fps)
    
    return animated_texture
