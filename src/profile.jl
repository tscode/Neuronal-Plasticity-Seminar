
include("EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 500
srand(1)
# init quantities
g = 1.2
ω_r = sprandn(N, N, 0.1)*g/sqrt(N*0.1)
ω_f = 2(rand(N, 1) - 0.5)
ω_o = 1randn(1, N)
neuron_in = 0.5randn(N)
readout = 2randn(1)
# Function for the task
f(t) = cos(t) + 0.5sin(3t)

n = 10000
# The types needed for the simulation
task    = ev.FunctionTask( f )
net     = ev.NetworkTest( ω_r = ω_r, ω_f = ω_f, neuron_in = neuron_in, readout = readout, ω_o = ω_o )
rule    = ev.ForceRule( N, 1 )
teacher = ev.Teacher( rule, 0.2, net.time, n/2 )


@time @rec net.time net.readout[1] for i in 1:n
    ev.update!(net) 
    ev.learn!(net, teacher, task)
end

writedlm("profile.dat", [ ev.REC[1] f(ev.REC[1]) ev.REC[2] ])

#=using PyPlot=#
#=plot(T, result)=#
#=plot(T, f(T))=#

