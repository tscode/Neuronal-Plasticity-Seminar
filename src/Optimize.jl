using EvoNet: AbstractRating, AbstractEnvironment
using EvoNet.Utils
using EvoNet.Param
using EvoNet.Generate
# files
include("optimize/record.jl") # *internal*
include("optimize/optimizer.jl")
include("optimize/genetic_optimizer.jl")
include("optimize/annealing_optimizer.jl")
# Types
export AbstractOptimizer, GeneticOptimizer, AnnealingOptimizer
# Functions
export get_recorder, set_callback!,
       init_population!, step!, save_evolution,
       default_callback, anneal
