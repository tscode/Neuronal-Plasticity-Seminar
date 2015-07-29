#
# EVONET
#

module EvoNet

const dt = 0.1

# Utility and helper types/functions, mending shortcomings of julia 0.3.
module Utils
  include("utils/Utils.jl")
end 
using .Utils

# The main network class, a single network
include("network.jl")

# This module contains types and functions for the learning procedure of
# a single network. 
module Learning
  include("learning/Learning.jl")
end 
using .Learning

# Parameterizations for Generators
module Param 
  include("param/Param.jl")
end 
using .Param

# The actual generators
module Generate
  include("generate/Generate.jl")
end 
using .Generate

# Challenges are task generators that one can 
# draw different, but similar, tasks from.
include("challenge.jl")
# types

# Environments contain hints and attributes for the
# Optimizers. Environments may e.g. blacklist that
# certain parameters change and contain the allowed
# challenges for the optimization process
include("environment.jl")

# Additional
include("rating.jl") # *internal*

# Fitness functions assign generators success
# ratings for given environments
include("fitness.jl")


module Optimize
include("optimize/Optimize.jl")
end # module Optimize
using .Optimize

end # module EvoNet
