#
# ENVIRONMENT
#

# The environment that the networks have to compete in. Most importantly,
# the environment provides the tasks to be completed by the learning
# networks. [It may have additional influence of the dynamics of evolution]

abstract AbstractEnvironment

type Environment <: AbstractEnvironment
    challenges::Vector{AbstractChallenge}  # Different challenges the networks have to be good at

    size::Int     # a hint to the genetic optimizer about how sparse resources are
    contamination # a hint regarding the mutation rate
    blacklist::Vector{ASCIIString} # Contains genes (parameters) not allowed to change
end

add_challenge(env::Environment, ch::AbstractChallenge) = push!(env.challenges, ch)


# create an default environment that can be used for fast simulations
function default_environment(; size::Int = typemax(Int), 
                               contamination::Real = 0.,
                               blacklist::Vector{ASCIIString}=ASCIIString[],
                               challenge::AbstractChallenge = Challenges.simple_wave() )

    # return the final environment with some default choices
    return Environment( AbstractChallenge[ challenge ], typemax(Int), 0, ASCIIString[] )
end
