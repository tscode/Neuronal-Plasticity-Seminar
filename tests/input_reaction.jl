
include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 600
generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.1, feedback = 2) #2. )
# init quantities

# a "taktgeber"
function r(t; freq=1/(20*6), amp=1, rel_width=10)
    t = t - floor(t*freq)*1/freq - 1/(2*freq)
    return amp*exp(-t.^2/freq/rel_width)
end
g(t) = 0.5r(t)

# Function for the task
f(t) = cos(2pi*t/(20*6)) + 0.5sin(2pi*t*5/(20*6)) + r(t+5, rel_width = 1000)

n = 50000
# The types needed for the simulation
task    = ev.FunctionTask( [f], [g], fluctuations=0.0 )
net     = ev.generate( generator, 0 )
rule    = ev.ForceRule( N, 0.1 )
evl     = ev.Evaluator( 100, 0, net )
teacher = ev.Teacher( rule, 0.2, net.time, evl, n*ev.dt, true)


@time @rec net.time net.output[1] for i in 1:n
    ev.learn!(net, teacher, task)
end
#=print(net.ω_o)=#

# let some time pass between lerning and evaluation
ev.evaluate(evl, task, 1000, rec=false)

ev.reset(evl)
print("result: ")
print(ev.evaluate(evl, task, 1000, rec=true))

writedlm("input_reaction.dat", [ ev.REC[1] f(ev.REC[1]) g(ev.REC[1]) ev.REC[2]])

#=using PyPlot=#
#=plot(T, result)=#
#=plot(T, f(T))=#

