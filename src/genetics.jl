include("recorder.jl")

type GeneticOptimizer{T, S <: AbstractSuccessRating}
  rng::AbstractRNG

  population::Vector{T} # vector of generators
  success::Vector{S}

  fitness::Function # maps T → S : returns a multidimensional fitness measure
  compare::Function # (S, S) → bool : compares two fitness measures, returns True if first arg is better than second

  generation::Int   # Counts the number of generations that have been calculated
  recorder::Recorder        # this recorder records parameters and success for each network in a generation as
                            # key 1 and the means as key 2
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

function rate_population_parallel{T, S}(opt::GeneticOptimizer{T, S}; seed::Integer=randseed(opt.rng))
  rng = MersenneTwister(seed)
  gene_tuples = [ (gene, randseed(rng)) for gene in opt.population ]
  opt.success = collect(pmap(x -> opt.fitness(x[1], rng=MersenneTwister(x[2])), gene_tuples))
end



function init_population!{T,S}( opt::GeneticOptimizer{T, S}, base_element::T, N::Integer )
  # must NOT use fill here, since this only gives references!
  opt.population = [ deepcopy(base_element) for i in 1:N ]
  opt.success    = [ S(0,0,0,0) for i in 1:N ]

  # load parameters
  params = export_params( base_element )
  # randomize networks
  for el in opt.population
    for (key,val) in params
      params[key] = random_param(val, rng=opt.rng)
    end
    import_params!( el, params )
  end

  # calculate initial fitness
  opt.success = rate_population_parallel(opt)
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
  means = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  lidx = 1
  # replace dead entities
  for i = 1:length(opt.population)
    # alive index is the same as population index
    if !alive[i]
      # for now, only mutate: rewirte popultion[i] (which is not alive) with a mutation of living[lidx] (which was a good net)
      mutate!(opt, opt.population[i], opt.population[living[lidx]])
      lidx += 1
    else
      data = [opt.success[i].quota, opt.success[i].quality, opt.population[i].size, opt.population[i].p, opt.population[i].gain, opt.population[i].feedback]
      means += data
      record(opt.recorder, 1, [opt.generation, i , data... ])
    end
  end
  # record means
  record( opt.recorder, 2, 2*means / length(opt.population) )

  # re-evaluate population
  opt.success = rate_population_parallel(opt, seed=randseed(opt.rng))

  opt.generation += 1
end

function calculate_next_generation!( opt::GeneticOptimizer, parents::Vector{AbstractGenerator}, targets::Vector{AbstractGenerator})
  lidx = 1
  for t in targets
    if randbool(opt.rng)
      t = mutate!(opt, t, parents[lidx])
    else
      t = recombine!(opt, t, parents[lidx], parents[lidx % length(parents) + 1])
    end

    # make lidx round-trip, so this works even if we require no relation between parents and targets sizes
    lidx = lidx % length(parents) + 1
  end
end

function mutate!( opt::GeneticOptimizer, target::AbstractGenerator, source::AbstractGenerator )
  # load parameters
  params = export_params( source )
  # randomize networks
  parray = [p for p in params]
  # change a single parameter
  pidx = convert(Int, round(rand(opt.rng) * length(parray) + 0.5))
  params[parray[pidx][1]] = random_param(parray[pidx][2], 9, rng=opt.rng)
  import_params!( target, params )
end

function recombine!( opt::GeneticOptimizer, target::AbstractGenerator, A::AbstractGenerator, B::AbstractGenerator )
  # combine A and B as parents for a new Generator target
  # load parameters
  params = export_params( target )
  ap = export_params( A )
  bp = export_params( B )
  # randomize networks
  for param : params
    if( randbool(opt.rng) )
      params[param[1]] = ap[param[1]]
    else
      params[param[1]] = bp[param[1]]
    end
  end

  import_params!( target, params )
end

function random_param( v, n = 1; rng::AbstractRNG=MersenneTwister(randseed()) )
   if isa(v[3], Int)
    nval = convert(Int, round((n*v[3] + rand(rng) * (v[2] - v[1]) + v[1])/(n+1)))
  else
    nval = (n*v[3] + rand(rng) * (v[2] - v[1]) + v[1]) / (n+1)
  end
  return (v[1], v[2], nval )
end

function save_evolution(file, opt::GeneticOptimizer)
  writedlm(file, hcat(opt.recorder[1]...)')
  writedlm("mean_"+file, hcat(opt.recorder[2]...)')
end
