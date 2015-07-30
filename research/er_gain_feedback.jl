using EvoNet
ev = EvoNet

#optimize secondary parameters (feedback, gain)


# here we need to set up our final task set
ch   = ev.complex_wave(n = 1)
# blacklist all but gain and feedback
env  = ev.Environment(challenge=ch, blacklist=["size", "percentage"])
# create the optimizer
gopt = ev.GeneticOptimizer( ev.fitness_in_environment, ev.compare_fitness, env=env )

# initialize the population by using the
N = 10 # use 100 for final run
p = 0.1
ertop = ev.ErdösRenyiTopology(p)
gen  = ev.SparseFRGenerator( N, topology = ertop )
ev.init_population!(gopt, gen, 10)

if N != 100
  info("this seems to be a test run. use N=100 to create final results")
end

for i = 1:25
  ev.step!(gopt)
  ev.save_evolution("er_gain_feedback.dat", gopt)
end

