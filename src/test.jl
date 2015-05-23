include("task.jl")
include("learning_rule.jl")
include("network.jl")

# create a random network

net = NetworkTest(randn(10,10) )
rule = ForceRule( 10, 1 )
task = FunctionTask( [sin;] )

print(5)
