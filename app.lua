dofile('constants.lua')
dofile('eval.lua')

math.randomseed(os.time()) -- Get different number for each execution

local function choice (t)
  -- Return a random element from a table
  return t[math.random(1,#t)]
end

local function get_random_bit()
  -- Return integer 0 or 1
  return math.random(0,1)
end

local function get_random_gene()
  -- Return binary string with @gene_len characters
  local gene, gene_len = "", 4
  for i = 1, 4 do
     gene = gene .. get_random_bit()
  end
  return gene
end

local function get_random_individual()
  -- Return table of @CHROMOSOME_LENGTH binary string
  local chromosome = {}
  for i = 1, CHROMOSOME_LENGTH do
     chromosome[i] = get_random_gene()
  end
  return chromosome
end

local function get_random_population()
  -- Return table of @POPULATION_COUNT table of @CHROMOSOME_LENGTH binary string
  local population = {}
  for i = 0, POPULATION_COUNT do
    population[i] = get_random_individual()
  end
  return population
end

local function gene_to_code(binary_string)
  -- Convert binary string to decimal and use the decimal value to return @char_table[converted_decimal]
  local result, char_table = 0, {0,1,2,3,4,5,6,7,8,9,"+","-","*","/"}
  for i = 0, #binary_string do
    local pow, number = #binary_string - i, string.sub(binary_string,i,i)
    if number == "1" then
      result = result + (2^pow)
    end
    i = i + 1
  end
  return char_table[result]
end

local function get_individual_solution(individual)
  -- Convert table of binary string to string follow pattern "Number|Symbol|Number"
  local solution, expected_type, code, j = "", {"number", "string"}, nil, 1
  for i = 1, #individual do
    code = gene_to_code(individual[i])
    if type(code) == expected_type[j] then
      solution = solution .. code
      j = (function() if j == 1 then return 2 else return 1 end end)()
    end
  end
  solution = solution:gsub('[^%d]$', '')
  if solution == "" then solution = '0' end
  return solution
end

local function get_individual_fitness (individual)
  -- Evaluate the fitness (1/abs(goal-result)) of individual and return it
  local solution = get_individual_solution(individual)
  return 1/math.abs(EXPECTED_RESULT-math.eval(solution))
end

local function grade_population (population)
  -- Evaluate fitness of population
  local graded_population = {}
  for i=1,#population do
    graded_population[i] = {}
    graded_population[i][1] = population[i]
    graded_population[i][2] = get_individual_fitness(population[i])
  end
  table.sort(graded_population, function(a,b) return a[2] > b[2] end)
  return graded_population
end

local function evolve_population (population)
  -- Select almost best and a few random individual, crossover and mutate them
  local graded_population = grade_population(population)
  local average_grade = 0
  local resolved = false

  for i=1,#graded_population do
    average_grade = average_grade + graded_population[i][2]
    if graded_population[i][2] == math.huge then
      resolved = true
    end
  end
  average_grade = average_grade / POPULATION_COUNT

  if resolved == true then
    return resolved, population, average_grade, graded_population
  end

  -- Select individuals to reproduce
  local parents = {}
  for i=1,GRADED_RETAIN_COUNT do
    table.insert(parents, graded_population[i][1])
  end

  for i=GRADED_RETAIN_COUNT,#graded_population do
    if math.random() < CHANCE_RETAIN_NONGRATED then
      table.insert(parents, graded_population[i][1])
    end
  end

  -- Crossover parents to create children
  local desired_len = POPULATION_COUNT - #parents
  local children = {}
  while (#children < desired_len) do
      local child = {}
      local father = choice(parents)
      local mother = choice(parents)
      if father ~= mother then
        local parent = {father, mother}
        local c = math.random(1,2)
        local u = (function() if c == 1 then return 2 else return 1 end end)()
        local chosen = parent[c]
        local unchosen = parent[u]
        for i=1,MIDDLE_CHROMOSOME_LENGTH do
          table.insert(child, chosen[i])
        end
        for i=MIDDLE_CHROMOSOME_LENGTH,CHROMOSOME_LENGTH do
          table.insert(child, unchosen[i])
        end
        table.insert(children, child)
      end
  end

  for i=1,#children do
    table.insert(parents, children[i])
  end

  -- Mutate some individual
  for i=1,#parents do
    if math.random() < MUTATION_CHANCE then
      local decomposed_str = {}
      local gene_to_modify = math.random(1,#parents[i])
      local place_to_modify = math.random(1,#parents[i][gene_to_modify])
      for j=1,#parents[i][gene_to_modify] do
        decomposed_str[j] = parents[i][gene_to_modify]:sub(j,j)
      end
      decomposed_str[place_to_modify] = get_random_bit()
      parents[i][gene_to_modify] = table.concat(decomposed_str, "")
    end

  end

  graded_population = grade_population(parents)

  for i=1,#graded_population do
    average_grade = average_grade + graded_population[i][2]
    if graded_population[i][2] == math.huge then
      resolved = true
    end
  end
  average_grade = average_grade / POPULATION_COUNT

  if resolved == true then
    return resolved, parents, average_grade, graded_population
  end

  return resolved, parents, average_grade, graded_population
end

local function main ()
  -- Main loop and print result
  local population = get_random_population()
  local graded_population

  local solution_found, actual_generation, average_grade = false, 0, 0
  while (solution_found == false and actual_generation < GENERATION_COUNT) do
    solution_found, population, average_grade, graded_population = evolve_population(population)
    actual_generation = actual_generation + 1
    if (actual_generation%255 == 0 or actual_generation == 1) then
      print('[' .. actual_generation .. " gen] - Average grade : " .. average_grade .. " (best:".. graded_population[1][2] .."|worst:".. graded_population[#graded_population][2] ..")")
    end
  end

  if solution_found then
    print('[' .. actual_generation .. ' gen] Solution found. -> ' .. get_individual_solution(graded_population[1][1]) .. " (it took "..os.clock().."s)")
  else
    print('[' .. actual_generation .. ' gen] Solution not found. (it took '..os.clock().."s)")
    print('-- Top solution -> ' .. get_individual_solution(graded_population[1][1]) .. ' = ' .. math.eval(get_individual_solution(graded_population[1][1])))
  end

end

main()
