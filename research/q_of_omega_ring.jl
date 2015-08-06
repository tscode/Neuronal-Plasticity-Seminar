push!(LOAD_PATH, "/scratch01/eriks/neural/Neuronal-Plasticity-Seminar/src/")

using EvoNet
#=ev = EvoNet=#

# F_C(ω) curve for an unoptimized genotype

@everywhere function rating(f)
  N = 100 # use 100 for final run
  p = .07
  k = 1.9
  ertop = EvoNet.ErdösRenyiTopology(p)
  ringtop = ev.RingTopology( k )
  
  gen  = ev.SparseFRGenerator( N, topology = ev.MetaTopology([ertop, ringtop], p = [0.02, 0.98]), gain = 1.2, feedback = 2 )
  ch   = EvoNet.simple_wave(amplitude=1, frequency=f, offset=0)
  env  = EvoNet.Environment(challenge=ch)
  s = EvoNet.fitness_in_environment(gen, samples=200, env=env)
  return EvoNet.get_value(s)
end

freq = logspace(-3, 0.5, 1000)
result = pmap(x->rating(x), freq)
writedlm("freqrange_ring.txt", [freq result])
