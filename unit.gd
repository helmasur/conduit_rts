# res://scripts/units/Unit.gd
extends CharacterBody2D
class_name Unit

# Ladda in våra nya script
#const UnitShared = preload("res://UnitShared.gd")
#const UnitAttributes = preload("res://UnitAttributes.gd")
#const UnitCollect = preload("res://UnitCollect.gd")
#const UnitBuild = preload("res://UnitBuild.gd")

var target_energy: float
var energy: float = 100.0
var health: float
var health_current: float = 1
var power: float
var speed: float

@export var health_prop: float = 0.5
@export var power_prop: float = 0.2
@export var speed_prop: float = 0.3


var target_health_prop: float
var target_power_prop: float
var target_speed_prop: float

var fsf: float

var mode: int = UnitShared.ActionMode.FREE
var mode_timer: float = 0.0

@export var collect_start_time: float = 0.0
@export var collect_stop_time: float = 0.0
@export var base_collect_rate: float = 5.0

@export var build_start_time: float = 0.0
@export var build_stop_time: float = 0.0
@export var build_cost: float = 50.0
@export var build_scene: PackedScene = preload("res://unit.tscn")
@export var build_target_energy: float = 50.0
@export var build_transfer_rate: float = 10.0
@export var final_health_prop: float = 0.5
@export var final_speed_prop: float = 0.3
@export var final_power_prop: float = 0.2

var building_unit: CharacterBody2D = null

var is_selected: bool = false
var destination: Vector2

func _ready() -> void:
	target_health_prop = health_prop
	target_speed_prop = speed_prop
	target_power_prop = power_prop
	UnitAttributes.normalize_proportions(self)
	add_to_group("units")
	destination = global_position

func _physics_process(delta: float) -> void:
	handle_state_machine(delta)

	if mode == UnitShared.ActionMode.FREE:
		var dist = destination.distance_to(global_position)
		if dist > 2.0:
			var dir = (destination - global_position).normalized()
			velocity = dir * UnitAttributes.get_speed_value(self)
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

	global_position = Utils.wrap_position(global_position)

	UnitAttributes.update_proportions(self, delta)

	fsf = Utils.calc_free_space_factor(global_position)
	queue_redraw()

func _draw() -> void:
	if is_selected:
		var size = 30.0
		var rect = Rect2(Vector2(-size/2, -size/2), Vector2(size, size))
		draw_rect(rect, Color(0,1,0), false, 2.0)

func handle_state_machine(delta: float) -> void:
	match mode:
		UnitShared.ActionMode.COLLECT_STARTING,UnitShared.ActionMode.COLLECTING, UnitShared.ActionMode.COLLECT_STOPPING:
			UnitCollect.handle_collect_state(self, delta)

		UnitShared.ActionMode.BUILD_STARTING, UnitShared.ActionMode.BUILDING, UnitShared.ActionMode.BUILD_STOPPING:
			UnitBuild.handle_build_state(self, delta)
			
		UnitShared.ActionMode.UNDER_CONSTRUCTION:
			pass

		_:
			# ActionMode.FREE eller annat
			pass

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		self.add_to_group("selected_units")
	else:
		self.remove_from_group("selected_units")

func set_destination(pos: Vector2) -> void:
	destination = pos

func start_collecting() -> void:
	UnitCollect.start_collecting(self)

func stop_collecting() -> void:
	UnitCollect.stop_collecting(self)

func start_build() -> void:
	UnitBuild.start_build(self)

func stop_build() -> void:
	UnitBuild.stop_build(self)

func apply_damage(amount: float) -> void:
	UnitAttributes.apply_damage(self, amount)

func build_finished() -> void:
	UnitAttributes.build_finished(self)

func _on_collect_button_pressed() -> void:
	if mode == UnitShared.ActionMode.FREE:
		start_collecting()
	elif mode == UnitShared.ActionMode.COLLECTING:
		stop_collecting()

func _on_build_button_pressed() -> void:
	if mode == UnitShared.ActionMode.FREE:
		start_build()
	elif mode == UnitShared.ActionMode.BUILDING:
		stop_build()
