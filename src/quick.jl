
module QuickUse

import EvoNet: fitness_in_environment, Environment, 
               test_fitness_for_task, test_fitness_of_generator,
               get_task, simple_periodic, complex_periodic,
               simple_wave, complex_wave, simple_sawtooth,
               complex_sawtooth, ellipse, circle, test_challenge,
               add_challenge

import EvoNet: AbstractEnvironment, Environment,
               AbstractChallenge, ListChallenge,
               CombinedChallenge, ParametricChallenge

importall Generate
importall Optimize

export fitness_in_environment, Environment, 
       test_fitness_for_task, test_fitness_of_generator,
       get_task, simple_periodic, complex_periodic,
       simple_wave, complex_wave, simple_sawtooth,
       complex_sawtooth, ellipse, circle, test_challenge,
       add_challenge, compare_fitness
export generate
export get_recorder, set_callback!, 
       init_population!, step, save_evolution,
       default_callback, anneal

export AbstractEnvironment, Environment
       AbstractChallenge, ListChallenge,
       CombinedChallenge, ParametricChallenge
export AbstractTopology, ErdösRenyiTopology,
       RingTopology, FeedForwardTopology,
       CommunityTopology,
       AbstractGenerator, SparseFRGenerator,
       SparseLRGenerator
export AbstractOptimizer, GeneticOptimizer, AnnealingOptimizer

end
