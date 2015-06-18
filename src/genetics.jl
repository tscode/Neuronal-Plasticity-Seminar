include("types.jl")

type GeneticOptimizer{T, S <: AbstractSuccessRating}
  rng::AbstractRNG

  population::Vector{T}
  success::Vector{S}

  fitness::Function # maps T → S : returns a multidimensional fitness measure
  compare::Function # (S, S) → bool : compares two fitness measures, returns True if first arg is better than second
  function GeneticOptimizer(fitness::Function, compare::Function;
                            population::Vector{T}=T[], success::Vector{S}=S[], seed::Int=0)
      new(MersenneTwister(seed), population, success, fitness, compare)
  end
end

#=function GeneticOptimizerFunction{T,S}(fitness::Function, compare::Function)=#
  #=GeneticOptimizer{T, S}(MersenneTwister(), T[], S[], fitness, compare)=#
#=end=#

#=function call{T, S}(::Type{GeneticOptimizer{T,S}}, fitness::Function, compare::Function)=#
  #=GeneticOptimizer{T, S}(MersenneTwister(), T[], S[], fitness, compare)=#
#=end=#


function init_population!{T,S}( opt::GeneticOptimizer{T, S}, base_element::T, N::Integer )
  opt.population = fill(base_element, N)
  opt.success = fill(S(0,0,0,0), N)

  # load parameters
  params = export_params( base_element )
  # randomize networks
  for el in opt.population
    for v in params
      params[v[1]] = random_param(v[2])
    end
    import_params!( el, params )
  end

  # calculate initial fitness
  for i in 1:length(opt.population)
    opt.success[i] = opt.fitness(opt.population[i])
  end

end

function step!( opt::GeneticOptimizer )
  # marks whether an entity is still alive
  alive = fill(true, length(opt.population))
  # collection of all living nets
  living = Int64[]

  order = shuffle(collect(1:length(opt.population))) # TODO specify RNG

  # fight: just compare the old fitnesses
  for i = 2:2:length(opt.population)
    if opt.compare(opt.success[order[i-1]], opt.success[order[i]])
      alive[order[i]] = false
      push!(living, order[i-1])
    else
      alive[order[i-1]] = false
      push!(living, order[i])
    end
  end

  print(alive)
  success = [0.0,0.0,0.0]
  lidx = 1
  # replace dead entities
  for i = 1:length(opt.population)
    if !alive[i]
      # for now, only mutate
      mutate!(opt, opt.population[living[lidx]])
      lidx += 1

      #calculate new score
      opt.success[i] = opt.fitness(opt.population[i])
    else
      success[1] += opt.success[i][1]
      success[2] += opt.success[i][2]
      success[3] += opt.population[i].size
    end
  end

  # success measure
  println(2*success/length(opt.population))
end


function mutate!( opt::GeneticOptimizer, gen::AbstractGenerator )
  # load parameters
  params = export_params( gen )
  # randomize networks
  for v in params
    params[v[1]] = random_param(v[2], 9)
  end
  import_params!( gen, params )
end

function random_param( v, n = 1)
   if isa(v[3], Int)
    nval = int(round((n*v[3] + rand() * (v[2] - v[1]) + v[1])/(n+1)))
  else
    nval = (n*v[3] + rand() * (v[2] - v[1]) + v[1]) / (n+1)
  end
  return (v[1], v[2], nval )
end
