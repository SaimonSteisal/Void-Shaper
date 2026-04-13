@tool
extends Control
class_name PatternEditorGUI

# Сигналы
signal pattern_saved(pattern_name: String)
signal pattern_loaded(pattern_name: String)
signal texture_generated(texture: Texture2D)

# UI компоненты
@onready var color_picker_primary: ColorPickerButton = $VBoxContainer/HSplitContainer/LeftPanel/Colors/PrimaryColor
@onready var color_picker_secondary: ColorPickerButton = $VBoxContainer/HSplitContainer/LeftPanel/Colors/SecondaryColor
@onready var color_picker_accent: ColorPickerButton = $VBoxContainer/HSplitContainer/LeftPanel/Colors/AccentColor

@onready var noise_scale_slider: HSlider = $VBoxContainer/HSplitContainer/LeftPanel/NoiseSettings/ScaleSlider
@onready var noise_scale_label: Label = $VBoxContainer/HSplitContainer/LeftPanel/NoiseSettings/ScaleLabel
@onready var octaves_slider: HSlider = $VBoxContainer/HSplitContainer/LeftPanel/NoiseSettings/OctavesSlider
@onready var persistence_slider: HSlider = $VBoxContainer/HSplitContainer/LeftPanel/NoiseSettings/PersistenceSlider

@onready var tile_size_spinbox: SpinBox = $VBoxContainer/HSplitContainer/LeftPanel/General/TileSize
@onready var seed_spinbox: SpinBox = $VBoxContainer/HSplitContainer/LeftPanel/General/SeedValue

@onready var preview_texture: TextureRect = $VBoxContainer/HSplitContainer/RightPanel/Preview/PreviewTexture
@onready var pattern_name_line: LineEdit = $VBoxContainer/HSplitContainer/LeftPanel/General/PatternName

@onready var mosaic_checkbox: CheckBox = $VBoxContainer/HSplitContainer/LeftPanel/Rules/MosaicCheck
@onready var mosaic_size_slider: HSlider = $VBoxContainer/HSplitContainer/LeftPanel/Rules/MosaicSize
@onready var edge_checkbox: CheckBox = $VBoxContainer/HSplitContainer/LeftPanel/Rules/EdgeDetectionCheck
@onready var edge_threshold_slider: HSlider = $VBoxContainer/HSplitContainer/LeftPanel/Rules/EdgeThreshold

var generator: PatternTextureGenerator
var current_pattern: Dictionary = {}
var preview_timer: Timer
var is_loading: bool = false

func _ready():
    generator = PatternTextureGenerator.new()
    _setup_timer()
    _connect_signals()
    _load_pattern_list()
    generate_preview()

func _setup_timer():
    preview_timer = Timer.new()
    preview_timer.wait_time = 0.5
    preview_timer.one_shot = true
    preview_timer.timeout.connect(generate_preview)
    add_child(preview_timer)

func _connect_signals():
    # Цвета
    color_picker_primary.color_changed.connect(_on_color_changed)
    color_picker_secondary.color_changed.connect(_on_color_changed)
    color_picker_accent.color_changed.connect(_on_color_changed)
    
    # Шум
    noise_scale_slider.value_changed.connect(_on_noise_setting_changed)
    octaves_slider.value_changed.connect(_on_noise_setting_changed)
    persistence_slider.value_changed.connect(_on_noise_setting_changed)
    
    # Общие настройки
    tile_size_spinbox.value_changed.connect(_on_general_setting_changed)
    seed_spinbox.value_changed.connect(_on_general_setting_changed)
    pattern_name_line.text_changed.connect(_on_pattern_name_changed)
    
    # Правила
    mosaic_checkbox.toggled.connect(_on_rule_changed)
    mosaic_size_slider.value_changed.connect(_on_rule_changed)
    edge_checkbox.toggled.connect(_on_rule_changed)
    edge_threshold_slider.value_changed.connect(_on_rule_changed)

func _load_pattern_list():
    var list = $VBoxContainer/HSplitContainer/LeftPanel/PatternList
    if not list:
        return
    
    # Очистка списка
    for child in list.get_children():
        child.queue_free()
    
    # Загрузка паттернов
    var dir = DirAccess.open("res://patterns/")
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".json"):
                var pattern_name = file_name.replace(".json", "")
                var btn = Button.new()
                btn.text = pattern_name
                btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
                btn.pressed.connect(_load_pattern.bind(pattern_name))
                list.add_child(btn)
            file_name = dir.get_next()

func _load_pattern(pattern_name: String):
    is_loading = true
    var pattern = generator.load_pattern(pattern_name)
    if pattern.is_empty():
        push_error("Failed to load pattern: " + pattern_name)
        is_loading = false
        return
    
    current_pattern = pattern
    pattern_name_line.text = pattern_name
    
    # Установка цветов
    var colors = pattern.get("base_colors", {})
    color_picker_primary.color = Color.html(colors.get("primary", "#808080"))
    color_picker_secondary.color = Color.html(colors.get("secondary", "#404040"))
    color_picker_accent.color = Color.html(colors.get("accent", "#A0A0A0"))
    
    # Настройки шума
    var noise_params = pattern.get("noise_params", {})
    noise_scale_slider.value = noise_params.get("scale", 0.5)
    octaves_slider.value = noise_params.get("octaves", 2)
    persistence_slider.value = noise_params.get("persistence", 0.5)
    seed_spinbox.value = noise_params.get("seed", randi())
    
    # Размер тайла
    tile_size_spinbox.value = pattern.get("tile_size", 16)
    
    # Правила
    var rules = pattern.get("rules", [])
    for rule in rules:
        if rule.get("type") == "mosaic":
            mosaic_checkbox.button_pressed = true
            mosaic_size_slider.value = rule.get("cell_size", 4)
        elif rule.get("type") == "edge_detection":
            edge_checkbox.button_pressed = true
            edge_threshold_slider.value = rule.get("threshold", 0.3)
    
    is_loading = false
    generate_preview()
    pattern_loaded.emit(pattern_name)

func _update_current_pattern():
    current_pattern["tile_size"] = int(tile_size_spinbox.value)
    current_pattern["pattern_name"] = pattern_name_line.text
    
    current_pattern["base_colors"] = {
        "primary": color_picker_primary.color.to_html(),
        "secondary": color_picker_secondary.color.to_html(),
        "accent": color_picker_accent.color.to_html()
    }
    
    current_pattern["noise_params"] = {
        "scale": noise_scale_slider.value,
        "octaves": int(octaves_slider.value),
        "persistence": persistence_slider.value,
        "seed": int(seed_spinbox.value)
    }
    
    var rules = []
    if mosaic_checkbox.button_pressed:
        rules.append({
            "type": "mosaic",
            "cell_size": int(mosaic_size_slider.value),
            "variation": 0.15
        })
    
    if edge_checkbox.button_pressed:
        rules.append({
            "type": "edge_detection",
            "threshold": edge_threshold_slider.value,
            "color": "#2D3748"
        })
    
    current_pattern["rules"] = rules

func generate_preview():
    if is_loading or current_pattern.is_empty():
        return
    
    _update_current_pattern()
    var img = generator.generate_from_pattern(current_pattern)
    var texture = ImageTexture.create_from_image(img)
    preview_texture.texture = texture
    texture_generated.emit(texture)

# ========== СЛОТЫ СИГНАЛОВ ==========

func _on_color_changed(_new_color: Color):
    if not is_loading:
        preview_timer.start()

func _on_noise_setting_changed(_value: float):
    if not is_loading:
        noise_scale_label.text = "Scale: %.2f" % noise_scale_slider.value
        preview_timer.start()

func _on_general_setting_changed(_value: float):
    if not is_loading:
        preview_timer.start()

func _on_pattern_name_changed(new_text: String):
    if not is_loading:
        current_pattern["pattern_name"] = new_text

func _on_rule_changed(_value = null):
    if not is_loading:
        preview_timer.start()

# ========== КНОПКИ ==========

func _on_SaveButton_pressed():
    if pattern_name_line.text.is_empty():
        _show_message("Please enter pattern name!")
        return
    
    _update_current_pattern()
    var err = generator.save_pattern(current_pattern, pattern_name_line.text)
    if err == OK:
        pattern_saved.emit(pattern_name_line.text)
        _show_message("Pattern saved: " + pattern_name_line.text)
        _load_pattern_list()
    else:
        _show_message("Error saving pattern!")

func _on_LoadButton_pressed():
    if pattern_name_line.text.is_empty():
        _show_message("Please enter pattern name!")
        return
    _load_pattern(pattern_name_line.text)

func _on_GenerateButton_pressed():
    generate_preview()

func _on_ExportButton_pressed():
    if current_pattern.is_empty():
        _show_message("No pattern to export!")
        return
    
    var img = generator.generate_from_pattern(current_pattern)
    var output_path = "res://textures/generated/%s.png" % pattern_name_line.text
    img.save_png(output_path)
    _show_message("Exported: " + output_path)

func _on_CreateDefaultsButton_pressed():
    generator.create_default_patterns()
    _load_pattern_list()
    _show_message("Default patterns created!")

func _show_message(text: String):
    if has_node("MessageLabel"):
        var label = $MessageLabel
        label.text = text
        label.visible = true
        await get_tree().create_timer(2.0).timeout
        label.visible = false
