include("recorder.jl")

type GeneticOptimizer{T, S <: AbstractSuccessRating}
  rng::AbstractRNG

  population::Vector{T} # vector of generators
  success::Vector{S}

  fitness::Function # maps T → S : returns a multidimensional fitness measure
  compare::Function # (S, S) → bool : compares two fitness measures, returns True if first arg is better than second

  generation::Int   # Counts the number of generations that have been calculated
  recorder::Recorder
  function GeneticOptimizer(fitness::Function, compare::Function;
                            population::Vector{T}=T[], success::Vector{S}=S[], seed::Int=0)
      new(MersenneTwister(seed), population, success, fitness, compare, 0, Recorder())
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
  #=for i in 1:length(opt.population)=#
    #=opt.success[i] = opt.fitness(opt.population[i])=#
  #=end=#
  opt.success = collect(pmap(gen -> opt.fitness(gen, rng=opt.rng), opt.population))

end

function step!( opt::GeneticOptimizer )
  println("processing generation $(opt.generation)")

  # marks whether an entity is still alive
  alive = fill(true, length(opt.population))
  # collection of all living nets
  living = Int64[]

  order = shuffle(opt.rng, collect(1:length(opt.population)))

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

  # TODO better way to save these values
  success = [0.0,0.0,0.0]
  lidx = 1
  # replace dead entities
  for i = 1:length(opt.population)
    if !alive[i]
      # for now, only mutate
      mutate!(opt, opt.population[living[lidx]])
      lidx += 1
    else
      success[1] += opt.success[i].quota
      success[2] += opt.success[i].quality
      success[3] += opt.population[i].size
      record(opt.recorder, 1, [i, opt.generation, opt.success[i].quota, opt.success[i].quality, opt.population[i].size, opt.population[i].p, opt.population[i].gain, opt.population[i].feedback ])
    end
  end
  opt.success = collect(pmap(gen -> opt.fitness(gen, rng=opt.rng, samples = 50), opt.population))

  # success measure
  println(2*success/length(opt.population))

  opt.generation += 1
end


function mutate!( opt::GeneticOptimizer, gen::AbstractGenerator )
  # load parameters
  params = export_params( gen )
  # randomize networks
  parray = [p for p in params]
  # change a single parameter
  pidx = int(round(rand(opt.rng) * length(parray) + 0.5))::Int
  params[parray[pidx][1]] = random_param(parray[pidx][2], 9)
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

function save_evolution(file, opt::GeneticOptimizer)
  writedlm(file, hcat(opt.recorder[1]...)')
end
