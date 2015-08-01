#
# CHALLENGE
#

# A challenge is something you get a certain type of task from. The tasks
# you get should be quantitatively similar, since a challenge is used to
# check how well networks learn a narrow range of tasks
#
# How versatile networks are is then tested by letting them compete
# in different challenges

# This type of callenge simply holds a list of possible tasks
# that are then created at random when asked

abstract AbstractChallenge

type ListChallenge <: AbstractChallenge
    tasks::Vector{AbstractTask}
end
#
function get_task(ch::ListChallenge; rng::AbstractRNG=MersenneTwister(EvoNet.Utils.randseed()))
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


# This challenge takes a template for a function and an array of functions
# providing parameters for
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

#----------------------------------------------------------------------------------------#


# Helper type


function simple_periodic( f::Function; amplitude=(0.5, 1.5), args... )
    return complex_periodic( f, n=1, amplitude=amplitude; args... )
end

simple_wave(; args...)  = simple_periodic(x -> sin(2π*x); args...)
complex_wave(; args...) = complex_periodic(x -> sin(2π*x); args...)

simple_sawtooth(; args...) = simple_periodic(sawtooth_function; args...)
complex_sawtooth(; args...) = complex_periodic(sawtooth_function; args...)

# generating periodics with specified amplitudes, frequencies and phases by taking a
# periodic f. The user must assure that f indeed is periodic with periode length 1 !
function complex_periodic( f::Function;
                           n=4, amplitude=(0.75, 1.5), frequency=(0.1, 1.0),
                           phase=(0., 1.),             offset=(-0.2, 0.2),
                           logfreq=true,
                           clock=false,                clock_frequency=1., # relative freq
                           clock_width=(0.05, 0.1),    clock_amplitude=(0.4, 0.6),
                           clock_phase=(0,1),          clock_offset=(0., 0.) )

    # if this is false, we get less than two samples per period!!!!!!
    @assert( maximum(frequency) < 0.5 / dt, "frequency impossible for current dt" )

    # define the parameter-distributions
    # the number of waves
    num_waves(rng) = n
    # the wave amplitudes
    amps = Function[ rng -> normal(rng, amplitude...) * 3/(3i) for i in 1:n ]
    # the frequencies
    if logfreq
      freqs = Function[ rng -> exp(unif(rng, map(log, frequency...))) ]
    else
      freqs = Function[ rng -> unif(rng, frequency...) ]
    end
    for i in 2:n push!( freqs, rng -> rand(rng, 0.0:0.25:1) + rand(rng, 1:min(8,2i)) ) end

    # the phases
    phases = Function[ rng -> unif(rng, phase...) for i in 1:n ]
    # the offsets
    off(rng) = unif(rng, offset...)
    # define the function that shall be called
    function otemplate(time::Float64, params::Vector{Float64})
        n = convert(Int, params[1])
        result = params[2] * f( time * params[2+n] + params[2+2n] ) + params[1+3n+1]
        for i in 2:n
            result += params[1+i] * f( time * params[1+n+i] * params[2+n] + params[1+2n+i] )
        end
        return result
    end

    # the clock distributions for the input
    clock_dists = clock_param_dists( clock_amplitude, clock_frequency, clock_width,
                                     clock_phase, clock_offset )
    # clock input function
    if clock itemplates = Function[ clock_template( 2+n, 3n+3 ) ]
    else     itemplates = Function[] end
    # collect all parameters
    param_dists = Function[ num_waves, amps..., freqs..., phases..., off, clock_dists... ]
    # return the brand new challenge
    return EvoNet.ParametricChallenge( Function[ otemplate ],
                                       itemplates,
                                       param_dists )
end

function ellipse(; a=(1., 1.5), b=(0.5, 1.), frequency=(0.1, 1.), phase=(0., 1.) )
    # parameter distributions
    amp1(rng)  = normal(rng, a...)
    amp2(rng)  = normal(rng, b...)
    freq(rng)  = unif(rng, frequency...)
    ph(rng)    = normal(rng, phase...)
    # define the two templates we need
    function template1(time::Float64, params::Vector{Float64})
        return params[1] * cos(time * params[3] + params[4])
    end
    function template2(time::Float64, params::Vector{Float64})
        return params[2] * sin(time * params[3] + params[4])
    end
    # create the challenge
    return EvoNet.ParametricChallenge( Function[ template1, template2 ],
                                       Function[],
                                       Function[ amp1, amp2, freq, ph ] )
end

function circle(; r=(0.5, 1.5), frequency=(0.1, 1.), phase=(0., 1.) )
    # parameter distributions
    amp(rng)   = normal(rng, r...)
    freq(rng)  = unif(rng, frequency...)
    ph(rng)    = normal(rng, phase...)
    # define the two templates we need
    function template1(time::Float64, params::Vector{Float64})
        return params[1] * cos(time * params[2] + params[3])
    end
    function template2(time::Float64, params::Vector{Float64})
        return params[1] * sin(time * params[2] + params[3])
    end
    # create the challenge
    return EvoNet.ParametricChallenge( Function[ template1, template2 ],
                                       Function[],
                                       Function[ amp, freq, ph ] )
end


function test_challenge(ch::EvoNet.AbstractChallenge; T::Real=500.)
    task = EvoNet.get_task(ch)
    output = zeros(convert(Int, round(T/0.01)), length(task.ofuncs))
    input  = zeros(convert(Int, round(T/0.01)), length(task.ifuncs))
    t = linspace(0, T, round(T/0.01))
    for i in 1:length(task.ofuncs)
        output[:,i] = map( x -> task.ofuncs[i](x), t)
    end
    for i in 1:length(task.ifuncs)
        input[:,i]  = map( x -> task.ifuncs[i](x), t)
    end
    return (output, input)
end


# Helping stuff

function clock_param_dists(amplitude, frequency, width, phase, offset)
    amp(rng)   = normal(rng, amplitude...)
    freq(rng)  = frequency
    peakw(rng) = normal(rng, width...)
    ph(rng)    = unif(rng, phase...)
    off(rng)   = normal(rng, offset...)
    return Function[amp, freq, peakw, ph, off]
end

function clock_template( freq_pos::Integer, param_pos::Integer )
    function template(time::Float64, params::Vector{Float64})
        # fetch all parameters
        orig_freq = params[freq_pos]
        amp       = params[param_pos+0]
        rel_freq  = params[param_pos+1]
        width     = params[param_pos+2]
        phase     = params[param_pos+3]
        offset    = params[param_pos+4]
        time_ = time - floor(time*orig_freq*rel_freq) / (orig_freq*rel_freq) + phase/orig_freq/rel_freq
        # use them to calculate the function value of the clock; use three elements of the sum to do so.
        # save for 0 <= phase <= 1, no guarantee for other phases
        return amp * exp( -((time_ + 0/orig_freq/rel_freq) * orig_freq / 0.5width)^2 ) +
               amp * exp( -((time_ - 1/orig_freq/rel_freq) * orig_freq / 0.5width)^2 ) +
               amp * exp( -((time_ - 2/orig_freq/rel_freq) * orig_freq / 0.5width)^2 ) + offset
    end
    return template
end

function sawtooth_function(time::Float64)
    time_ = time - floor(time)
    return time_ < 0.5 ? 1 - 4*time_ : 4*time_ - 3
end

