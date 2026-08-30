class_name GardenPlot
extends InteractionZone
## Thin view over GardenState's plot at `plot_index` — the actual state
## lives in that autoload (see its docstring for why), this node just
## renders it and turns clicks into GardenState calls.
##
## The background art already shows each plot as bare tilled soil by
## default, so EMPTY needs no overlay at all. DUG and the growth stages
## each show one overlay/sprite on top of that; WetSoil is a separate
## timed flash on top of everything, shown briefly after any successful
## watering regardless of stage. DUG and SPROUT have real art now; the
## growth-stage sprites are per-ingredient (Ingredient.growth_sprite/
## mature_sprite) and still pending. WetSoil deliberately has none — a
## painted "just watered" patch kept reading as flat/unconvincing (tried
## and dropped), so it's a procedural radial darkening instead (see
## _build_wet_soil_texture) rather than more art to chase.

## Shared by every plot/species — the sprout right after planting doesn't
## vary by ingredient, only growing/mature do (Ingredient.growth_sprite/
## mature_sprite). Flat under assets/hut/ like every other asset in the
## game, not a garden/ subfolder — one less thing to get wrong uploading.
const SHARED_SPROUT_TEXTURE_PATH := "res://assets/hut/garden_sprout.png"
const DUG_HOLE_TEXTURE_PATH := "res://assets/hut/garden_dug_hole.png"

const WET_SOIL_SECONDS := 3.0
const WET_SOIL_TEXTURE_SIZE := 128 ## px; small is fine, it's just a soft radial blob.

const DUG_COLOR := Color(0.25, 0.16, 0.08, 0.85)
const SPROUT_COLOR := Color(0.5, 0.7, 0.35, 1)
## Darkest point of the procedural "just watered" patch — fades to fully
## transparent at the edge, see _build_wet_soil_texture().
const WET_SOIL_COLOR := Color(0.15, 0.09, 0.04, 0.55)

@export var plot_index: int = 0

## Emitted on click when this plot needs the planting minigame (empty or
## already dug) — garden.gd opens PlantingUI for it, then calls refresh()
## once the UI closes.
signal planting_requested(plot: GardenPlot)
signal harvested(plot: GardenPlot, ingredient_id: StringName)

@onready var dug_hole_color: ColorRect = $DugHoleColor
@onready var dug_hole_texture: TextureRect = $DugHoleTexture
@onready var growth_icon_color: ColorRect = $GrowthIconColor
@onready var growth_icon_texture: TextureRect = $GrowthIconTexture
@onready var wet_soil_color: ColorRect = $WetSoilColor
@onready var wet_soil_texture: TextureRect = $WetSoilTexture
@onready var label: Label = $Label
@onready var _wet_soil_timer: Timer = $WetSoilTimer

var _wet_soil_texture: GradientTexture2D

func _ready() -> void:
	super._ready()
	_wet_soil_texture = _build_wet_soil_texture()
	activated.connect(_on_activated)
	GameCalendar.day_changed.connect(func(_d: int) -> void: refresh())
	_wet_soil_timer.timeout.connect(func() -> void: _set_visual(wet_soil_color, wet_soil_texture, WET_SOIL_COLOR, null, false))
	refresh()

func _on_activated(_zone: InteractionZone) -> void:
	var plot := GardenState.get_plot(plot_index)
	match plot.stage:
		GardenState.Stage.EMPTY, GardenState.Stage.DUG:
			planting_requested.emit(self)
		GardenState.Stage.SPROUT, GardenState.Stage.GROWING:
			if GardenState.water(plot_index):
				_flash_wet_soil()
			refresh()
		GardenState.Stage.MATURE:
			var ingredient_id := GardenState.harvest(plot_index)
			harvested.emit(self, ingredient_id)
			refresh()

func _flash_wet_soil() -> void:
	_set_visual(wet_soil_color, wet_soil_texture, WET_SOIL_COLOR, _wet_soil_texture, true)
	_wet_soil_timer.start(WET_SOIL_SECONDS)

## A soft-edged dark blob, radially faded from WET_SOIL_COLOR at the
## center to fully transparent at the rim — built once at runtime rather
## than loaded, so "just watered" needs no art asset at all.
func _build_wet_soil_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, WET_SOIL_COLOR)
	gradient.set_color(1, Color(WET_SOIL_COLOR.r, WET_SOIL_COLOR.g, WET_SOIL_COLOR.b, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = WET_SOIL_TEXTURE_SIZE
	texture.height = WET_SOIL_TEXTURE_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture

func refresh() -> void:
	var plot := GardenState.get_plot(plot_index)

	var dug_texture: Texture2D = load(DUG_HOLE_TEXTURE_PATH) if ResourceLoader.exists(DUG_HOLE_TEXTURE_PATH) else null
	_set_visual(dug_hole_color, dug_hole_texture, DUG_COLOR, dug_texture, plot.stage == GardenState.Stage.DUG)

	match plot.stage:
		GardenState.Stage.EMPTY:
			label.text = ""
			_set_visual(growth_icon_color, growth_icon_texture, SPROUT_COLOR, null, false)
		GardenState.Stage.DUG:
			label.text = "Викопано"
			_set_visual(growth_icon_color, growth_icon_texture, SPROUT_COLOR, null, false)
		GardenState.Stage.SPROUT:
			var sprout_texture: Texture2D = load(SHARED_SPROUT_TEXTURE_PATH) if ResourceLoader.exists(SHARED_SPROUT_TEXTURE_PATH) else null
			_set_visual(growth_icon_color, growth_icon_texture, SPROUT_COLOR, sprout_texture, true)
			label.text = "Паросток (%d/%d)" % [plot.days_grown, plot.days_to_growing]
		GardenState.Stage.GROWING:
			var growing_ingredient := IngredientDatabase.get_ingredient(plot.ingredient_id)
			var growing_color := growing_ingredient.placeholder_color if growing_ingredient else SPROUT_COLOR
			var growing_texture := growing_ingredient.growth_sprite if growing_ingredient else null
			_set_visual(growth_icon_color, growth_icon_texture, growing_color, growing_texture, true)
			label.text = "Росте... (%d/%d)" % [plot.days_grown, plot.days_to_growing + plot.days_to_mature]
		GardenState.Stage.MATURE:
			var mature_ingredient := IngredientDatabase.get_ingredient(plot.ingredient_id)
			var mature_color := mature_ingredient.placeholder_color if mature_ingredient else SPROUT_COLOR
			var mature_texture := mature_ingredient.mature_sprite if mature_ingredient else null
			_set_visual(growth_icon_color, growth_icon_texture, mature_color, mature_texture, true)
			label.text = "Готово!"

## Shows `texture` if provided, else falls back to a flat `color` box —
## same fallback rule as FloatingToken's ingredient icon. `shown = false`
## hides both regardless.
func _set_visual(color_node: ColorRect, texture_node: TextureRect, color: Color, texture: Texture2D, shown: bool) -> void:
	if not shown:
		color_node.visible = false
		texture_node.visible = false
		return
	if texture != null:
		texture_node.texture = texture
		texture_node.visible = true
		color_node.visible = false
	else:
		color_node.color = color
		color_node.visible = true
		texture_node.visible = false
