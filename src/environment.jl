#
# ENVIRONMENT
#

# The environment that the networks have to compete in. Most importantly,
# the environment provides the tasks to be completed by the learning
# networks. [It may have additional influence of the dynamics of evolution]

abstract AbstractEnvironment

type Environment <: AbstractEnvironment
    challenges::Vector{AbstractChallenge}  # Different challenges the networks have to be good at

    contamination # a hint regarding the mutation rate
    blacklist::Vector{UTF8String} # Contains genes (parameters) not allowed to change
end

function Environment(; contamination::Real = 0.,
                       blacklist = UTF8String[],
                       challenge::AbstractChallenge = simple_wave() )
    blacklist = UTF8String[ entry for entry in blacklist ]
    return Environment( AbstractChallenge[ challenge ], contamination, blacklist )
end

add_challenge(env::Environment, ch::AbstractChallenge) = push!(env.challenges, ch)
add_blacklist_entry(env::Environment, ch::AbstractChallenge) = push!(env.challenges, ch)
