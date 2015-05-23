
include("EvoNet.jl")
ev = EvoNet

# create a random network
N = 500
srand(1)
net = ev.NetworkTest(ω_r = sprandn(N,N, 0.1)*1.5/sqrt(N*0.1), ω_f = 2(rand(N, 1) - 0.5), neuron_in = 0.5randn(N), readout = 0.5randn(1) )
rule = ev.ForceRule( N, 1 )
f(x) = 0.5(3sin(x/20) - 1.8cos(x/10))
task = ev.FunctionTask( [f;] )
teacher = ev.Teacher(rule, 0.2)

n = 20000

result = zeros(n)
T = zeros(n)
@time for i in 1:n
    result[i] = ev.teach!(teacher, net, task)[1]
    T[i] = net.time
end

writedlm("data2.dat", [ T f(T) result ])

#=using PyPlot=#
#=plot(T, result)=#
#=plot(T, f(T))=#

