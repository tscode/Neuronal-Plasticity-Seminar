include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 100
generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.0, feedback = 2) #2. )

gopt = ev.GeneticOptimizer{ev.SparseMatrixGenerator, (Float64, Float64, Float64) }( ev.test_fitness_of_generator, ev.compare_fitness )

ev.init_population!(gopt, generator, 30)

for i = 1:100
  ev.step!(gopt)
end
#@time println(ev.test_fitness_of_generator(generator, samples=100))
