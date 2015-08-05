push!(LOAD_PATH, "/scratch01/eriks/neural/Neuronal-Plasticity-Seminar/src/")

using EvoNet
#=ev = EvoNet=#

# F_C(ω) curve for an unoptimized genotype

@everywhere function rating(f)
  N = 100 # use 100 for final run
  p = .0998625185385132
  gain = 1.1356512394227996
  feedback = 10.985208608245522
  ertop = EvoNet.ErdösRenyiTopology(p)
  gen  = EvoNet.SparseFRGenerator( N, topology = ertop, gain = gain, feedback = feedback )
  ch   = EvoNet.simple_wave(amplitude=1, frequency=f, offset=0)
  env  = EvoNet.Environment(challenge=ch)
  s = EvoNet.fitness_in_environment(gen, samples=200, env=env)
  return EvoNet.get_value(s)
end

freq = logspace(-3, 0.5, 1000)
result = pmap(x->rating(x), freq)
writedlm("freqrange_high.txt", [freq result])
