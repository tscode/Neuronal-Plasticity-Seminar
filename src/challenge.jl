#
# CHALLENGE
#
# A challenge is something you get tasks from when asked. The tasks you
# get should be quantitatively similar, since a challenge is used to
# check how well networks learn a narrow range of tasks
#
# How versatile networks are is then tested by letting them compete
# in different challenges

# This type of callenge simply holds a list of possible tasks
# that are then created at random when asked
type ListChallenge <: AbstractChallenge
    tasks::Vector{AbstractTask}
end
#
function get_task(ch::ListChallenge; rng::AbstractRNG=MersenneTwister(randseed()))
    return rand( rng, ch.tasks )
end

# This challenge is the combination of two other challenges and draws from
# them at random; which actual challenge is chosen is uniformly distributed
type CombinedChallenge <: AbstractChallenge
    challenges::Vector{AbstractChallenge}
end
#
function get_task(ch::CombinedChallenge; rng::AbstractRNG=MersenneTwister(randseed()))
    get_task( rand(rng, ch), rng )
end


# This challenge takes a template for a function and an array of functions providing parameters for
type ParametricChallenge <: AbstractChallenge # random parameter task creator
    out_templates::Vector{Function} # f(time, param_vals) -> ℝ
    in_templates::Vector{Function}  # f(time, param_vals) -> ℝ
    param_dists::Vector{Function}   # rng -> Float64, parameter value
end
#
function get_task(ch::ParametricChallenge; rng::AbstractRNG=MersenneTwister(randseed()))
    params = Float64[ dist(rng) for dist in ch.param_dists ]
    out_funcs = Function[ t -> temp(t, params) for temp in ch.out_templates ]
    in_funcs = Function[ t -> temp(t, params) for temp in ch.in_templates ]
    return FunctionTask( out_funcs, in_funcs )
end


