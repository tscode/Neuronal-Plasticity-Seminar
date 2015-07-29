# need the exported symbols of Utils and Param
using EvoNet: Network, LRNetwork, AbstractNetwork
using EvoNet.Utils
using EvoNet.Param
# files
include("generate/topology.jl")
include("generate/generator.jl")
# types
export AbstractTopology, ErdösRenyiTopology,
       RingTopology, FeedForwardTopology,
       CommunityTopology, MetaTopology,
       AbstractGenerator, SparseFRGenerator,
       SparseLRGenerator
# functions
export generate
