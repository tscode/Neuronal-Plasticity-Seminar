#
# ENVIRONMENT
#

# The environment that the networks have to compete in. Most importantly,
# the environment provides the tasks to be completed by the learning
# networks. [It may have additional influence of the dynamics of evolution]

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
                               blacklist::Vector{ASCIIString}=ASCIIString[] )
    # give the distributions for three parameters
    param1(rng) = 2π / (rand(rng) * 100 + 10) / dt  # frequency
    param2(rng) = 1 + randn(rng) / 2                # amplitude
    param3(rng) = rand(rng) * 2π                    # phase shift
    # create the function template that uses instances of the parameters used above
    function template(time::Float64, params::Vector{Float64})
        return params[2] * sin(time * params[1] + params[3])
    end
    # obtain the challenge
    ch = ParametricChallenge( Function[ template ], 
                              Function[], 
                              Function[ param1, param2, param3 ] )
    # return the final environment with some default choices
    return Environment( AbstractChallenge[ ch ], typemax(Int), 0, ASCIIString[] )
end
