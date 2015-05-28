
include("EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 1000
generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.1  )
# init quantities
# Function for the task
f(t) = cos(1.5t)

n = 10000
# The types needed for the simulation
task    = ev.FunctionTask( [f], fluctuations=0.1 )
net     = ev.generate( generator, 5 )
rule    = ev.ForceRule( N, 0.1 )
teacher = ev.Teacher( rule, 0.2, net.time, n )

ev.set_deterministic!(task, false)

@time @rec net.time net.output[1] for i in 1:n
    ev.update!(net)
    ev.learn!(net, teacher, task)
end
#=print(net.ω_o)=#

evl = ev.Evaluator(100, 0.0)
println(ev.evaluate(evl, net, task, 100))
println(evl.timeshift)

writedlm("profile.dat", [ ev.REC[1] f(ev.REC[1]) ev.REC[2] ])

#=using PyPlot=#
#=plot(T, result)=#
#=plot(T, f(T))=#

