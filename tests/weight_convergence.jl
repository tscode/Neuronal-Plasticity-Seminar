
include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 1000
generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.2  )
# init quantities
# Function for the task
f(t) = cos(2.5t) + 0.5sin(1.5t)# cos(t) + 0.5sin(3t)

n = 50000
# The types needed for the simulation
task    = ev.FunctionTask( [f] )
net     = ev.generate( generator, 5 )
rule    = ev.ForceRule( N, 0.1 )
teacher = ev.Teacher( rule, 0.2, net.time, n*ev.dt/2 )


@time @rec net.time net.output[1] vec(net.ω_o) for i in 1:n
    ev.update!(net)
    ev.learn!(net, teacher, task)
end

Δω_o = [norm(ev.REC[3][i] - ev.REC[3][i+1]) for i in 1:(n-1)] / N

#=print(net.ω_o)=#

writedlm("weight.dat", [ ev.REC[1] f(ev.REC[1]) ev.REC[2] [0; Δω_o] ])

ev.clear_records()


#=using PyPlot=#
#=plot(T, result)=#
#=plot(T, f(T))=#

