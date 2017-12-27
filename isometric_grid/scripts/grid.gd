# Based on: https://github.com/GDquest/Godot-30-days-tutorial-challenge-2017/blob/master/final/09-Isometric%20grid-based%20movement/Grid.gd

# Collection of functions to work with a Grid. Stores all its children in the grid array
tool
extends TileMap

enum ENTITY_TYPES {PLAYER, OBSTACLE, COLLECTIBLE, BUILDING}

export var grid_size = Vector2(16, 16)
export var max_obstacles = 5
export var move_outside_tiles = false
export(PackedScene) var Player
export(PackedScene) var Obstacle

var tile_size = get_cell_size()
# The map_to_world function returns the position of the tile's top left corner in isometric space,
# we have to offset the objects on the Y axis to center them on the tiles
var tile_offset = Vector2(0, tile_size.y / 2)

var grid = []
var Sorter = null
var obstacles_count = 0
# onready var Obstacle = preload("res://Obstacle.tscn")
# onready var Player = preload("res://Player.tscn")
# We need to add the Player and Obstacles as children of the YSort node so when the player is below
# an obstacle on the screen Y axis, he'll be drawn above it
# onready var Sorter = get_child(0)

# With the Tilemap in isometric mode, Godot takes in account the center of the tiles 
# if the tilemap is properly configured in the inspector (Cell/Tile Origin)
# so we can remove the half_tile_size variable from the top-down grid example
# Aside from that, nothing changed, the grid works exactly the same!
func _ready():

	set_mode(MODE_ISOMETRIC)

	if not Sorter:
		Sorter = get_child(0)

	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			grid[x].append(null)

	# Player
	if Player && not Sorter.has_node("Player"):
		var new_player = Player.instance()
		# We still have to offset the objects on the Y axis to center them on the tiles
		new_player.target_pos = map_to_world(Vector2(4,4)) + tile_offset
		new_player.set_pos(new_player.target_pos)
		# Be careful to add the Player and Obstacles as children of the YSort node, not the grid!
		Sorter.add_child(new_player)

	# Obstacles
	add_obstacles()

		# for pos in positions:

func _enter_tree():
	Sorter = Sorter if Sorter else get_child(0)
	if Sorter && Sorter extends YSort:
		return

	add_children()

# Add YSort node child to order isometric
# tiles on Y axis
func add_children(parent=null, child_name="YSort"):
	Sorter = YSort.new()
	Sorter.set_name(child_name)
	add_child(Sorter)
	parent = parent if parent else self
	Sorter.set_owner(parent)

func add_obstacles():
	if Obstacle:
		var positions = []
		for x in range(max_obstacles):
			var placed = false
			while not placed && obstacles_count < 5:
				var grid_pos = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
				if not grid[grid_pos.x][grid_pos.y]:
					if not grid_pos in positions:
						positions.append(grid_pos)

						var new_obstacle = Obstacle.instance()
						new_obstacle.set_pos(map_to_world(grid_pos) + tile_offset)
						grid[grid_pos.x][grid_pos.y] = new_obstacle.get_name()
						Sorter.add_child(new_obstacle)
						obstacles_count += 1
						
						placed = true

func cartesian_to_isometric(vector):
	return Vector2(vector.x - vector.y, (vector.x + vector.y) / 2)

func get_cell_content(pos=Vector2()):
	return grid[pos.x][pos.y]


func is_cell_vacant(pos=Vector2(), direction=Vector2()):
	var grid_pos = world_to_map(pos) + direction

	if grid_pos.x < grid_size.x and grid_pos.x >= 0:
		if grid_pos.y < grid_size.y and grid_pos.y >= 0:
			return true if grid[grid_pos.x][grid_pos.y] == null else false
	return false


# Nothing new in this function either, the TileMap class takes care of the cartesian to iso conversion
func update_child_pos(pos, direction, type):
	var grid_pos = world_to_map(pos)
	grid[grid_pos.x][grid_pos.y] = null

	var new_grid_pos = grid_pos + direction
	grid[new_grid_pos.x][new_grid_pos.y] = type

	var target_pos = map_to_world(new_grid_pos) + tile_offset

	# Print statements help to understand what's happening. We're using GDscript's string format operator % to convert
	# Vector2s to strings and integrate them to a sentence. The syntax is "... %s" % value / "... %s ... %s" % [value_1, value_2]
	# print("Pos %s, dir %s" % [pos, direction])
	# print("Grid pos, old: %s, new: %s" % [grid_pos, new_grid_pos])
	# print(target_pos)
	return target_pos

# Returns true if the cell corresponding to a position is of the requestedtype
func is_cell_of_type(pos=Vector2(), type=null):
	var grid_pos = world_to_map(pos)
	return true if grid[grid_pos.x][grid_pos.y] == type else false

func cell_has_tile(pos=Vector2(), direction=Vector2()):
	var grid_pos = world_to_map(pos) + direction
	var used_cells = get_used_cells()

	if used_cells.size() > 0 && used_cells.has(grid_pos):
		return true
	return false

