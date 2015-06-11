include("types.jl")

type GeneticOptimizer{T, S}
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


function init_population{T,S}( opt::GeneticOptimizer{T, S}, base_element::T, N::Integer )
  opt.population = fill(base_element, (N,))
  opt.success = fill( S(), N )

  # load parameters
  params = export_params( base_element )
  # randomize networks
  for el in opt.population
    for v in params
      v[3] = rand() * (v[2] - v[1]) + v[1]
    end
    import_params!( el, params )
  end

  # calculate initial fitness
  for i in 1:length(population)
    opt.success[i] = opt.fitness(opt.population[i])
  end

end

function step!( opt::GeneticOptimizer )
  # marks whether an entity is still alive
  alive = fill(true, length(opt.population))
  order = shuffle(rng, 1:length(opt.population))

  # fight: just compare the old fitnesses
  for i = 2:2:length(opt.population)
    if opt.compare(opt.success[order[i-1]], opt.success[order[i]])
      alive[i] = false
    else
      alive[i-1] = false
    end
  end

  # replace dead entities
  for i = 1:length(opt.population)
    if !alive[i]
      # for now, only mutate
      mutate!(opt, opt.population[i])

      #calculate new score
      opt.success[i] = opt.fitness(opt.population[i])
    end
  end
end




function mutate!( opt::GeneticOptimizer, gen::AbstractGenerator )
  # load parameters
  params = export_params( gen )
  # randomize networks
  for v in params
    v[3] = (v[3] + rand() * (v[2] - v[1]) + v[1]) / 2.0
  end
  import_params!( gen, params )
end

