using EvoNet: AbstractRating, AbstractEnvironment
using EvoNet.Utils
using EvoNet.Param
using EvoNet.Generate
# files
include("record.jl") # *internal*
include("optimizer.jl")
include("genetic_optimizer.jl")
include("annealing_optimizer.jl")
# Types
export AbstractOptimizer, GeneticOptimizer, AnnealingOptimizer
# Functions
export get_recorder, set_callback!,
       init_population!, step!, save_evolution,
       default_callback, anneal
