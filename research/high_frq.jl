push!(LOAD_PATH, "/scratch01/eriks/neural/Neuronal-Plasticity-Seminar/src/")

using EvoNet
ev = EvoNet
#optimize secondary parameters (feedback, gain, percentage)


# here we need to set up our final task set
ch   = EvoNet.simple_wave(amplitude=1, frequency=(0.3, 3e0))
# blacklist all but gain and feedback
env  = ev.Environment(challenge=ch, blacklist=["size"])
# create the optimizer
gopt = ev.GeneticOptimizer( ev.fitness_in_environment, ev.compare_fitness, env=env )

# initialize the population by using the
N = 100 # use 100 for final run
p = 0.1
ertop = ev.ErdösRenyiTopology(p)
# choose gain and feedback far from the values of the original paper, to show 
# that the optimization works.
gen  = ev.SparseFRGenerator( N, topology = ertop, gain = 1.2, feedback = 2 )
ev.init_population!(gopt, gen, 50)

if N != 100
  info("this seems to be a test run. use N=100 to create final results")
end

for i = 1:50
  ev.step!(gopt)
  ev.save_evolution("high_frq_opt.dat", gopt)
end

