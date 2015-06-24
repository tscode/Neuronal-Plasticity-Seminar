#
# EVONET
#

module EvoNet

# Basic integration step for the network dynamic
const dt = 0.1

# abstract stuff
include("types.jl")
include("interface.jl")
include("parametric_object.jl")
include("meta_pobject.jl")

# extra convenience / needed stuff
include("recorder.jl")
include("random.jl")

# neuronal stuff
include("network.jl")
include("force_rule.jl")
include("reward_rule.jl")
include("task.jl")
include("challenge.jl")
include("environment.jl")
include("teacher.jl")
include("topology.jl")
include("generator.jl")
include("evaluator.jl")
include("fitness.jl")
include("genetics.jl")


end # module EvoNet
