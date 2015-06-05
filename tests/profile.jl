
include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 500
generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.1  )
# init quantities
# Function for the task
f(t) = cos(t) + 0.5sin(3t)
g(t) = 0

# The types needed for the simulation
task    = ev.FunctionTask( [f;], [g;] )
net     = ev.generate( generator, 5 )
rule    = ev.ForceRule( N, 1 )
evl     = ev.Evaluator( 100, 0, net )
teacher = ev.Teacher( rule, evl, max_time = 5000, adaptive = true )


@time @rec net.time net.output[1] while(!teacher.finished)
    ev.learn!(net, teacher, task)
end

ev.evaluate(evl, task, 1000, rec=false)

ev.reset(evl)

println(ev.evaluate(evl, task, 1000, rec=true))
#=print(net.ω_o)=#

writedlm("profile_new.dat", [ ev.REC[1] f(ev.REC[1]) ev.REC[2] ])

#=using PyPlot=#
#=plot(T, result)=#
#=plot(T, f(T))=#

