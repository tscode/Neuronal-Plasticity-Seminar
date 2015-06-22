#
# GENETICS
#

type GeneticOptimizer
  population::Vector{AbstractGenerator}   # vector of generators, all different genotypes
  success::Vector{AbstractSuccessRating}  # holds the current success ratings

  fitness::Function     # maps AbstractGenerator → AbstractSuccessRating
  compare::Function     # maps AbstractGenerator² → bool,
                        # returns true if first arg is better than second

  generation::Int       # counts the number of generations that have been simulated
  recorder::Recorder    # records genotype information
  rng::AbstractRNG      # an own rng for deterministic results

  # Constructor
  function GeneticOptimizer( fitness::Function, compare::Function;
                             population::Vector{AbstractGenerator}=AbstractGenerator[],
                             success::Vector{AbstractSuccessRating}=AbstractSuccessRating[],
                             seed::Uint32 = randseed() )
      new( population, success, fitness, compare, 0, Recorder(), MersenneTwister(seed) )
  end
end

# function to calculate the success values as fast as possible in parallel
# ATTENTION: Usage of this function makes it necessary to start julia appropriately
# for several processes
function rate_population_parallel(opt::GeneticOptimizer; seed::Integer=randseed())
  rng = MersenneTwister(seed)
  gene_tuples = [ (gene, randseed(rng)) for gene in opt.population ]
  return AbstractSuccessRating[ succ for succ in pmap( x -> opt.fitness(x[1],
                                                       rng=MersenneTwister(x[2])),
                                                       gene_tuples ) ]
end

function init_population!( opt::GeneticOptimizer, base_element::SparseLRGenerator, N::Integer ) ## TO BE GENERALIZED
  # provde defaults to be mutated later
  opt.population = AbstractGenerator[ deepcopy(base_element) for i in 1:N ]
  opt.success    = AbstractSuccessRating[ SuccessRating(0,0,0,0) for i in 1:N ]
  # load parameters
  params = export_params( base_element ) # Vector of AbstractParameters
  # randomize the generators in the population (genome-pool)
  for gen in opt.population
    for i in 1:length(params)
      params[i] = random_param( params[i], s = 5, rng=opt.rng )
    end
    import_params!( gen, params )
  end
  # calculate the initial success rates
  opt.success = rate_population_parallel(opt, seed=randseed(opt.rng))
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

function step!( opt::GeneticOptimizer ) ## TO BE GENERALIZED
  # provide the impatient programmer with some information
  println("processing generation $(opt.generation)")
  # marks whether an entity is still alive
  alive = fill( true, length(opt.population) )
  # collection of all living network indices
  living = Int64[]

  order = shuffle( opt.rng, collect(1:length(opt.population)) )

  # fight: just compare the old fitnesses
  for i = 2:2:length(opt.population)
    if opt.compare( opt.success[order[i-1]], opt.success[order[i]] )
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
    # alive index is the same as population index
    if !alive[i]
      # for now, only mutate: rewirte popultion[i] (which is not alive) with a mutation of living[lidx] (which was a good net)
      new_generator = mutate!(opt, opt.population[i], opt.population[living[lidx]])
      lidx += 1
    else
      success[1] += opt.success[i].quota
      success[2] += opt.success[i].quality
      success[3] += opt.population[i].params[3].val
      record(opt.recorder, 1, [opt.generation, i , opt.success[i].quota, opt.success[i].quality, opt.population[i].params[3].val, opt.population[i].params[1].val, opt.population[i].params[2].val, opt.population[i].params[4].val ])
    end
  end
  println(opt.success)
  opt.success = rate_population_parallel(opt, seed=randseed(opt.rng))

  # success measure
  println(2*success/length(opt.population))

  opt.generation += 1
end

function recombine( rng::AbstractRNG, A::AbstractGenerator, B::AbstractGenerator )
  # combine A and B as parents for a new Generator target
  # load parameters
  ap = export_params( A )
  bp = export_params( B )
  # randomize networks
  for i in 1:length(ap)
    if( randbool(rng) )
      @assert ap[i].name = bp[i].name "parameters do not match $(ap[i]) != $(bp[i])"
      ap[i] = bp[i] #should be safe, because export_params creates deep copies
    end
  end

  new_gen = deepcopy(A) # this assumes that A and B are equivalent!
  import_params!( new_gen, params )
  return new_gen
end

function mutate( rng::AbstractRNG, source::AbstractGenerator ) ## TO BE GENERALIZED
  # load parameters
  params = export_params( source )
  # choose parameter-index to mutate
  id = rand( rng, 1:length(params) )
  # make the mutation
  params[id] = random_param( params[id], rng=rng )
  # and reimport them
  target = deepcopy(source) # this assumes that A and B are equivalent!
  import_params!( target, params )
  return target
end

# create a new "mutated" parameter based on a given one
function random_param( param::Parameter{Int}; s::Real = 1.,              ## TO BE GENERALIZED
                       rng::AbstractRNG=MersenneTwister(randseed()) )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = convert(Int, round( param.val * (rand(rng)*0.2*s + 1 - 0.2*s*0.5) ))
  # Check if the new value is within the boundaries
  return Parameter{Int}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end


function random_param( param::Parameter{Float64}; s::Real = 1.,          ## TO BE GENERALIZED
                       rng::AbstractRNG=MersenneTwister(randseed()) )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = param.val * (rand(rng)*0.2*s + 1 - 0.2*s*0.5) #  0.9 ... 1.1 is default
  # Check if the new value is within the boundaries and return new param
  return Parameter{Float64}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end

function save_evolution(file, opt::GeneticOptimizer)
  writedlm(file, hcat(opt.recorder[1]...)')
#  writedlm(join(("mean_",file)), hcat(opt.recorder[2]...)')
end
