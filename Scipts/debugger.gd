extends Control

@onready var rena: Label = %rena
@onready var dave: Label = %dave
@onready var fredenic: Label = %fredenic

# ── Dave refs ──────────────────────────────────────────────────
@export var dave_node: Node  # assign Dave in Inspector

# ── Frednic refs ───────────────────────────────────────────────
@export var frednic_node: Node  # assign Frednic in Inspector

# ── Rena refs ──────────────────────────────────────────────────
@export var rena_node: Node  # assign Rena in Inspector


func _process(_delta: float) -> void:
	_update_dave()
	_update_frednic()
	_update_rena()

# ──────────────────────────────────────────────────────────────
func _update_dave() -> void:
	if not dave_node:
		dave.text = "[Dave] NOT ASSIGNED"
		return

	var state_name := _dave_state_name(dave_node.current_state)
	var route_str  := str(dave_node.current_route) if dave_node.current_route.size() > 0 else "[]"
	var idx        = dave_node.route_index
	var cam        = dave_node.current_cam
	var at_cam     = dave_node.current_route[idx] if (dave_node.current_route.size() > 0 and idx < dave_node.current_route.size()) else cam
	dave.text = (
        "[DAVE]\n"
		+ "State   : " + state_name + "\n"
		+ "Cam     : " + cam + "\n"
		+ "Route   : " + route_str + "\n"
		+ "Step    : " + str(idx) + " / " + str(dave_node.current_route.size()) + "\n"
		+ "At      : " + at_cam
	)

func _dave_state_name(s: int) -> String:
	match s:
		0: return "IDLE"
		1: return "MOVING"
		2: return "ATTACKING"
		3: return "RETURNING"
	return "UNKNOWN"

# ──────────────────────────────────────────────────────────────
func _update_frednic() -> void:
	if not frednic_node:
		fredenic.text = "[Frednic] NOT ASSIGNED"
		return

	var state_name := _frednic_state_name(frednic_node.current_state)
	var meter_pct  := "%.1f" % (frednic_node.meter * 100.0) + "%"
	var watched    := "YES" if frednic_node.is_being_watched else "no"
	var cam        = frednic_node.current_cam

	fredenic.text = (
        "[FREDNIC]\n"
		+ "State   : " + state_name + "\n"
		+ "Cam     : " + cam + "\n"
		+ "Meter   : " + meter_pct + "\n"
		+ "Watched : " + watched
	)

func _frednic_state_name(s: int) -> String:
	match s:
		0: return "IDLE"
		1: return "IN_OFFICE"
		2: return "JUMPSCARING"
	return "UNKNOWN"

# ──────────────────────────────────────────────────────────────
func _update_rena() -> void:
	if not rena_node:
		rena.text = "[Rena] NOT ASSIGNED"
		return

	var state_name := _rena_state_name(rena_node.current_state)
	var cam        = rena_node.current_cam
	var esc_idx    = rena_node.cam11_escalation_index
	var route_str  = str(rena_node.current_route) if rena_node.current_route.size() > 0 else "[]"
	var idx        = rena_node.route_index

	rena.text = (
        "[RENA]\n"
		+ "State   : " + state_name + "\n"
		+ "Cam     : " + cam + "\n"
		+ "CAM11   : pose " + str(esc_idx + 1) + " / 3\n"
		+ "Route   : " + route_str + "\n"
		+ "Step    : " + str(idx) + " / " + str(rena_node.current_route.size())
	)

func _rena_state_name(s: int) -> String:
	match s:
		0: return "IDLE"
		1: return "ESCALATING"
		2: return "MOVING"
		3: return "ATTACKING"
		4: return "RETURNING"
	return "UNKNOWN"

# ──────────────────────────────────────────────────────────────
# Call these from each animatronic when a jumpscare fires
# ──────────────────────────────────────────────────────────────
func notify_jumpscare(name: String) -> void:
	match name:
		"Dave":
			dave.text    = "⚠ GAME OVER — DAVE ⚠"
			dave.modulate = Color.RED
		"Frednic":
			fredenic.text    = "⚠ GAME OVER — FREDNIC ⚠"
			fredenic.modulate = Color.RED
		"Rena":
			rena.text    = "⚠ GAME OVER — RENA ⚠"
			rena.modulate = Color.RED
