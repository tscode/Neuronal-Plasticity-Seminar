push!(LOAD_PATH, "/scratch01/eriks/neural/Neuronal-Plasticity-Seminar/src/")

using EvoNet
ev = EvoNet

#optimize secondary parameters (feedback, gain)

# initialize the population by using the

#r = open("freqrange.txt", "w")
@everywhere function rating(f)
  N = 100 # use 100 for final run
  p = 0.1
  ertop = EvoNet.ErdösRenyiTopology(p)
  gen  = EvoNet.SparseFRGenerator( N, topology = ertop )
  ch   = EvoNet.simple_wave(n = 1, amplitude=1, frequency=f, offset=0)
  env  = EvoNet.Environment(challenge=ch)
  s = EvoNet.fitness_in_environment(gen, samples=100, env=env)
  return EvoNet.get_value(s)
end

freq = logspace(-3, 0.5, 200)
result = pmap(x->rating(x), freq)
writedlm("freqrange.txt", [freq result])
