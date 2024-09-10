extends Node

# Variables
@export var island_scene : PackedScene
@export var route_scene  : PackedScene
@export var border_scene : PackedScene

var islands     : Array # Array of islands
@onready var num_islands : int = $NumIslands.get_value()
var rng = RandomNumberGenerator.new()

@onready var map_size   : Vector2 = $IslandMap.get_size_with_decorations()
@onready var chart_size : Vector2 = $PopChart.get_size_with_decorations()
var chart_margin        : float = 0.1

var distances         : Array # 2D Array distance between each pair of islands
var best_distances    : Array[float] # Best route for each generation
var max_best_distance : float = 0.0
var min_best_distance : float = 0.0
var best_line         : Line2D

var num_candidates  : int = 100
var num_survivors   : int = 20
var init_candidates : Array
var candidates      : Array
var best_candidate  : Route
@onready var num_generations : int = $NumGenerations.get_value()
var num_elites      : int = 20

var graph_line : Line2D
var grid_size : int = 50

# Called when the node enters the scene tree for the first time. (Beginning)
func _ready():
	draw_borders()
	initialize_islands()
	
	$NumIslandsLabel.set_text("Num Islands: %d" % [$NumIslands.get_value()])
	$NumGenerationsLabel.set_text("Num Generations: %d" % [$NumGenerations.get_value()])
	
	if 0:
		var test_parents : Array
		var parent1 : Route = Route.new(num_islands, rng, [], distances)
		test_parents.append(parent1)
		var parent2 : Route = Route.new(num_islands, rng, [], distances)
		test_parents.append(parent2)
		parent1.print()
		parent2.print()
		var new_child : Route = Route.new(num_islands, rng, test_parents, distances)
		new_child.print()

# Adds borders around the island map, population chart, and axes
func draw_borders():
	var map_border = border_scene.instantiate()
	map_border.add_point(Vector2(0, 0))
	map_border.add_point(Vector2(map_size.x, 0))
	map_border.add_point(map_size)
	map_border.add_point(Vector2(0, map_size.y))
	map_border.set_closed(true)
	$IslandMap.add_child(map_border)
	
	var chart_border = border_scene.instantiate()
	chart_border.add_point(Vector2(0, 0))
	chart_border.add_point(Vector2(chart_size.x, 0))
	chart_border.add_point(chart_size)
	chart_border.add_point(Vector2(0, chart_size.y))
	chart_border.set_closed(true)
	$PopChart.add_child(chart_border)
	
	var axes = border_scene.instantiate()
	axes.add_point(Vector2(chart_size.x * chart_margin, chart_size.y * chart_margin))
	axes.add_point(Vector2(chart_size.x * chart_margin, chart_size.y * (1 - chart_margin)))
	axes.add_point(Vector2(chart_size.x * (1 - chart_margin), chart_size.y * (1 - chart_margin)))
	$PopChart.add_child(axes)

# Clears islands, initializes islands, distances, candidates
func initialize_islands():
#	var num_rows : int = grid_size
#	var num_cols : int = grid_size
	for i in islands:
		remove_child(i)
		i.free()
		
	islands.clear()
	
	for i in num_islands:
		var this_island = island_scene.instantiate()
		$IslandMap.add_child(this_island)
		var col : int = rng.randi_range(0, grid_size - 1)
		var row : int = rng.randi_range(0, grid_size - 1)
		this_island.position = Vector2(col * map_size.x / grid_size, row * map_size.y / grid_size)
		islands.append(this_island)
	
	initialize_distances()
	initialize_candidates()

# Clears distances, calculates and adds distances
func initialize_distances():
	distances.clear()
	for r in num_islands:
		distances.append([]) # Append empty array
		for c in num_islands:
			distances[r].append(0)
		
	for r in num_islands:
		for c in range(r + 1, num_islands):
			# print("%d, %d" % [r, c])
			var x_distance : float = islands[r].position.x - islands[c].position.x
			var y_distance : float = islands[r].position.y - islands[c].position.y
			var distance : float = sqrt(x_distance * x_distance + y_distance * y_distance)
			distances[r][c] = distance
			distances[c][r] = distance
	
	for r in num_islands:
		var row_string : String
		for c in num_islands:
			row_string += "%0.1f " % distances[r][c]
		# print(row_string)

# Clears candidates, creates new routes, updates max and min distance labels, removes graph line
func initialize_candidates():
	init_candidates.clear()
	for c in num_candidates:
		var new_route : Route = Route.new(num_islands, rng, [], distances)
		# for r in new_route:
		# 	print(r)
		init_candidates.append(new_route)
	init_candidates.sort_custom(sort_routes)
	draw_best_route(init_candidates[0])
	
	$MaxDistance.set_text("Max Distance: %0.1f" % [init_candidates[0].distance])
	$MinDistance.set_text("Min Distance: %0.1f" % [init_candidates[0].distance])
	
	if graph_line != null:
		remove_child(graph_line)
		graph_line.free()

# Returns true or false based on route distance
func sort_routes(a : Route, b : Route) -> bool:
	if a.distance < b.distance:
		return true
	return false

# Sorts candidates to determine best, min, and max, calls reproduce, mutate, and calculates distance
func process():
	# Determine survivors, eliminate others
	candidates.sort_custom(sort_routes)
	best_candidate = candidates[0]
	
	# print(candidates[0].distance)
	var best_distance : float = candidates[0].distance
	best_distances.append(best_distance)
	if best_distance > max_best_distance:
		max_best_distance = best_distance
	if best_distance < min_best_distance || min_best_distance == 0.0:
		min_best_distance = best_distance
		
	# Combine survivors to make children
	reproduce()
	
	# Mutation
	# for c in candidates:
	for i in range(1, num_islands - 1):
		var c : Route = candidates[i]
		c.mutate(rng)
		c.calc_distance(distances)

# Removes best line, adds new best line to island map
func draw_best_route(best_route : Route):
	if best_line != null:
		remove_child(best_line)
		best_line.free()
		
	best_line = get_line(best_route)
	$IslandMap.add_child(best_line)

# Determines parents and survivors, clears candidates, adds elites, adds candidates based on parents
func reproduce():
	# Determining parents
	var parents : Array
	for s in num_survivors:
		parents.append(candidates[s])
	
	# Killing all
	candidates.clear()
	
	for i in num_elites:
		candidates.append(parents[i])
	
	# Creating children
	for c in num_candidates - num_elites:
		var new_child : Route = Route.new(num_islands, rng, parents, distances)
		candidates.append(new_child)

	# Draw line

# Returns line between islands
func get_line(route : Route) -> Line2D:
	var this_route_line = route_scene.instantiate()
	for i in route.island_indexes:
		this_route_line.add_point(islands[i].position)
		this_route_line.set_closed(true)
	return this_route_line

# Removes graph line, creates graph line based on best distance per generation
func graph_results():
	# best_distances.clear()
	# best_distances.append(1000)
	# best_distances.append(800)
	# best_distances.append(200)
	# max_best_distance = 1000
	# min_best_distance = 200
	if graph_line != null:
		remove_child(graph_line)
		graph_line.free()
	
	graph_line = route_scene.instantiate()
	
	for g in best_distances.size():
		var gx : float = float(g) / float(best_distances.size())
		var px : float = (gx * (1.0 - 2.0 * chart_margin) + chart_margin) * chart_size.x
		var gy : float = 1.0 - ((best_distances[g] - min_best_distance) / (max_best_distance - min_best_distance))
		var py : float = (gy * (1.0 - 2.0 * chart_margin) + chart_margin) * chart_size.y
		graph_line.add_point(Vector2(px, py))
		# print("gx = %f, px = %f, gy = %f, py = %f, g = %f, %f" % [gx, px, gy, py, g, best_distances.size()])
	$PopChart.add_child(graph_line)
#	print("max: %0.1f" % [max_best_distance])
#	print("min: %0.1f" % [min_best_distance])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Initializes islands when 'Regenerate Islands' button pressed
func _on_regenerate_islands_pressed():
	initialize_islands()

# Initializes candidates when 'Regenerate Initial Pop' button pressed
func _on_regenerate_initial_pop_pressed():
	initialize_candidates()

# Empties max and min distance labels, runs process once for each generation when 'Simulate' button pressed
# Graphs results, draws best route, sets max and min distance
func _on_simulate_pressed():
	
	$MaxDistance.set_text("")
	$MinDistance.set_text("")
	
	candidates = init_candidates.duplicate()
	best_distances.clear()
	
	max_best_distance = 0.0
	min_best_distance = 0.0
	
	for g in num_generations:
		# print(g)
		process() # One generation
		# await get_tree().create_timer(1.0).timeout
	graph_results()
	
	draw_best_route(best_candidate)
	
	$MaxDistance.set_text("Max Distance: %0.1f" % [max_best_distance])
	$MinDistance.set_text("Min Distance: %0.1f" % [min_best_distance])

# Sets num islands based on 'Number of Islands' slider, initializes islands
func _on_num_islands_value_changed(value):
	num_islands = value
	initialize_islands()
	$NumIslandsLabel.set_text("Num Islands: %d" % [num_islands])

# Sets num generations based on 'Number of Generations' slider
func _on_num_generations_value_changed(value):
	num_generations = value
	$NumGenerationsLabel.set_text("Num Generations: %d" % [num_generations])
