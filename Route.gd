class_name Route

var island_indexes  : Array
var distance        : float = 0.0

# Based on parameters, creates route from scratch or from parents, calculates distance
func _init(num_islands : int, rng : RandomNumberGenerator, parents : Array, distances : Array):
	if parents.size() == 0:
		# Creates a child from scratch
		create_route_from_scratch(num_islands, rng)
	else:
		# Creates a child from parents
		create_route_from_parents(num_islands, rng, parents)

	calc_distance(distances)
	# print(distance)

# Calculates distances between islands, adds to distances array
func calc_distance(distances : Array):
	distance = 0.0
	for i in island_indexes.size():
		var curr : int = island_indexes[i]
		var prev : int = island_indexes[i - 1] # Index -1 = last element
		distance += distances[curr][prev]

# Generates random island indexes, calls swap
func create_route_from_scratch(num_islands : int, rng : RandomNumberGenerator):
	island_indexes = range(num_islands)
	for i in range(1, num_islands):
		var r : int = rng.randi_range(i, num_islands - 1)
		swap(r, i)

# Swaps island index elements given two indexes
func swap(first : int, second : int):
	var temp : int = island_indexes[first]
	island_indexes[first] = island_indexes[second]
	island_indexes[second] = temp

# Creates route using genes from two parents
func create_route_from_parents(num_islands : int, rng : RandomNumberGenerator, parents : Array):
	# Select parents
	# First and second parents can't be the same
	var p1_index  : int = rng.randi_range(0, parents.size() - 1)
	var p2_index : int = rng.randi_range(0, parents.size() - 2)
	if p2_index >= p1_index:
		p2_index += 1
		
#	print("p1_index = %d, p2_index = %d" % [p1_index, p2_index])
		
	var parent1     : Array = parents[p1_index].island_indexes.slice(1, num_islands)
	var parent2     : Array = parents[p2_index].island_indexes.slice(1, num_islands)
	var p1_genes    : Array
	var num_genes   : int = parent1.size() # number of genes being swapped
	var curr        : int = rng.randi_range(0, num_genes - 1)
	var num_from_p1 : int = rng.randi_range(0, num_genes - 1)
		
#	print("P1" + int_array_to_string(parent1))
#	print("P2" + int_array_to_string(parent2))

#	print("curr = %d, num_genes = %d" % [curr, num_genes])
		
	# Copy genes from first parent
	for i in num_from_p1:
		p1_genes.append(parent1[curr])
		curr = inc_genes(curr, num_genes)
	
#	print("P1_genes" + int_array_to_string(p1_genes))

	# Initialize route
	island_indexes.resize(num_genes)

#	print("Start" + int_array_to_string(island_indexes))
	# Copy genes from second parent
	var p2_genes_index : int = curr
	for i in num_genes - num_from_p1:
		while p1_genes.has(parent2[p2_genes_index]):
			p2_genes_index = inc_genes(p2_genes_index, num_genes)
		island_indexes[curr] = parent2[p2_genes_index]
		curr = inc_genes(curr, num_genes)
		p2_genes_index = inc_genes(p2_genes_index, num_genes)
#		print("-" + int_array_to_string(island_indexes))

#	print("copy from p2" + int_array_to_string(island_indexes))
	
	# Copy genes from p1_genes
	for i in num_from_p1:
		island_indexes[curr] = p1_genes[i]
		curr = inc_genes(curr, num_genes)
	
	island_indexes.push_front(0)
	
#	print("copy from p1" + int_array_to_string(island_indexes))	

# Increments current island index by one
func inc_genes(curr : int, num_genes : int) -> int:
	curr += 1
	if curr >= num_genes:
		curr -= num_genes
	return curr

# Randomly swaps two islands
func mutate(rng : RandomNumberGenerator):
	var first  : int = rng.randi_range(1, island_indexes.size() - 1)
	var second : int = rng.randi_range(1, island_indexes.size() - 1)
	swap(first, second)

# Prints string of island indexes (for testing)
func print():
	var s : String = "%0.1f" % [distance]
	s += int_array_to_string(island_indexes)
	print(s)

# Returns string containing elements of given array (for testing)
func int_array_to_string(a : Array) -> String:
	var s : String
	for i in a:
		var e : int
		if i == null:
			e = 0
		else:
			e = i
		s += "\t %d" % [e]
	return s
