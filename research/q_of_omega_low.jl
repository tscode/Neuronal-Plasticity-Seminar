push!(LOAD_PATH, "/scratch01/eriks/neural/Neuronal-Plasticity-Seminar/src/")

using EvoNet
#=ev = EvoNet=#

# F_C(ω) curve for an unoptimized genotype

@everywhere function rating(f)
  N = 100 # use 100 for final run
  p = 
  gain = 
  feedback = 
  ertop = EvoNet.ErdösRenyiTopology(p)
  gen  = EvoNet.SparseFRGenerator( N, topology = ertop, gain = gain, feedback = feedback )
  ch   = EvoNet.simple_wave(amplitude=1, frequency=f, offset=0)
  env  = EvoNet.Environment(challenge=ch)
  s = EvoNet.fitness_in_environment(gen, samples=200, env=env)
  return EvoNet.get_value(s)
end

freq = logspace(-3, 0.5, 200)
result = pmap(x->rating(x), freq)
writedlm("freqrange_unoptimized.txt", [freq result])
