
include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 500
generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.90  )
# init quantities
# Function for the task
r = 50
f(t) = cos(2.5t/r) + 0.5sin(1.5t/r) # cos(t) + 0.5sin(3t)

n = 200000
# The types needed for the simulation
task    = ev.FunctionTask( [f] )
net     = ev.generate( generator, 3 )
net2    = ev.SampleOutputNetwork(ω_r = net.ω_r, 
                              ω_i = net.ω_i,
                              ω_f = net.ω_f,
                              ω_o = net.ω_o[:,1:300],
                              neuron_in = net.neuron_in,
                              neuron_out = net.neuron_out,
                              output = net.output,
                              α = net.α,
                              time = net.time,
                              output_neurons = convert(Vector{Int}, 1:300)
                             )

rule    = ev.ForceRule( 300, 1/500 )
teacher = ev.Teacher( rule, 0.2, net2.time, n*ev.dt/2 )


@time @rec net2.time net2.output[1] for i in 1:n
    ev.update!(net2)
    ev.learn!(net2, teacher, task)
end

writedlm("profile_sample.dat", [ ev.REC[1] f(ev.REC[1]) ev.REC[2] ])

#=using PyPlot=#
#=plot(T, result)=#
#=plot(T, f(T))=#

