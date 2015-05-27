include("types.jl")

type Test{T} <: AbstractNetwork
    a::T
    function Test(a::T)
        new(a)
    end
end


type SampleOutputNetwork{T <: AAF} <: AbstractNetwork
    ω_r::T
    ω_i::Matrix{Float64}
    ω_f::Matrix{Float64}
    ω_o::Matrix{Float64} #

    neuron_in::Vector{Float64}    # same length as neurons
    neuron_out::Vector{Float64}   # what the neurons fired last step
    output::Vector{Float64}       # last output the network produced

    output_neurons::Vector{Int}   # holds indices of the neurons responsible 

    α::Function                   # mapping the neuron input to output, α for "activation"

                                  # to produce the network output
    time::Float64

    function SampleOutputNetwork( ω_r::T, ω_i::Matrix{Float64}, ω_f::Matrix{Float64}, ω_o::Matrix{Float64}, 
                      neuron_in::Vector{Float64}, neuron_out::Vector{Float64}, output::Vector{Float64}, 
                      output_neurons::Vector{Int}, α::Function, time::Float64 )

        #=# consistency checks=#
        #=# First, all dimensions=#
        @assert size(ω_r)[1] == size(ω_r)[2]      == size(ω_i)[1]       == size(ω_f)[1] ==
                length(neuron_in) == length(neuron_out) "inconsistent number of internal neurons"

        @assert size(ω_o)[1] == length(output) "inconsistent number of output channels"
        @assert size(ω_o)[2] == length(output_neurons) "inconsistent number of output neurons"
        

        # all indices in 'output_neurons' must be unique and between 1 and the number of neurons
        last = 0
        for index in output_neurons
            @assert index > last "index vector of output_neurons must be strictly monotonically increasing"
            last = index
        end
        @assert last <= size(ω_r)[1] "vector output_neurons contains index higher than the number of neurons"
        # create an instance, specialized on the given types
        return new(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, output, output_neurons, α, time)
    end # function Network
end

# "external" constructor so that one does not always have to type the parameter type stuff
function SampleOutputNetwork(; ω_r = error("internal weight matrix must be given"),   # weights_recurrent; for the recurrent neuron connections
                   ω_i::AAF = randn(size(ω_r)[1],1),            # weights_input; input->internal neurons
                   ω_f::AAF = randn(size(ω_r)[1],1),            # weights_feedback; output->internal neurons
                   output_neurons::Vector{Int} = convert(Vector{Int}, 1:size(ω_r)[2]),
                   ω_o::AAF = randn(1, length(output_neurons)),            # weights internal neurons -> output

                   α::Function = tanh,
                   neuron_in::Vector{Float64}  = randn(size(ω_r)[2]),
                   neuron_out::Vector{Float64} = α(neuron_in),
                   output::Vector{Float64}    = zeros(size(ω_o)[1]),
                   time::Real = 0.
                )
    return SampleOutputNetwork{typeof(ω_r)}(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, output, output_neurons, α, time)
end




# generic network class
type Network{T1 <: AAF, T2 <: AAF, T3 <: AAF, T4 <: AAF} <: AbstractNetwork
    ω_r::T1    # weights_recurrent; for the recurrent neuron connections
    ω_i::T2    # weights_input; input->internal neurons
    ω_f::T3    # weights_feedback; output->internal neurons
    ω_o::T4    # weights internal neurons -> output

    #neurons::Vector{NeuronType}
    # maybe put this into NeuronType
    neuron_in::Vector{Float64}    # same length as neurons
    neuron_out::Vector{Float64}   # what the neurons fired last step
    output::Vector{Float64}      # last output the network produced

    α::Function                   # mapping the neuron input to output, α for "activation"

    time::Float64


    # "internal" constructor -- only this one can then be called in programs
    function Network( ω_r::T1, ω_i::T2, ω_f::T3, ω_o::T4, neuron_in::Vector{Float64},
                      neuron_out::Vector{Float64}, output::Vector{Float64}, α::Function, time::Float64 )
        # consistency checks
        # First, all dimensions
        @assert size(ω_r)[1] == size(ω_r)[2]      == size(ω_i)[1]       == size(ω_f)[1] ==
                size(ω_o)[2] == length(neuron_in) == length(neuron_out) "Inconsistent number of internal neurons"

        @assert size(ω_o)[1] == length(output) "Inconsistent number of output neurons"

        # create an instance, specialized on the given types
        return new(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, output, α, time)
    end # function Network

end # type Network


# "external" constructor so that one does not always have to type the parameter type stuff
function NetworkTest(; ω_r = error("internal weight matrix must be given"),   # weights_recurrent; for the recurrent neuron connections
                   ω_i::AAF = randn(size(ω_r)[1],1),            # weights_input; input->internal neurons
                   ω_f::AAF = randn(size(ω_r)[1],1),            # weights_feedback; output->internal neurons
                   ω_o::AAF = randn(1,size(ω_r)[2]),            # weights internal neurons -> output

                   α::Function = tanh,
                   neuron_in::Vector{Float64}  = randn(size(ω_r)[2]),
                   neuron_out::Vector{Float64} = α(neuron_in),
                   output::Vector{Float64}    = zeros(size(ω_o)[1]),
                   time::Real = 0.
                )
    return Network{typeof(ω_r), typeof(ω_i), typeof(ω_f), typeof(ω_o)}(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, output, α, time)
end


function update!(net::Network, ext_in::Array{Float64}=zeros(size(net.ω_i)[2]))
    @assert size(ext_in)[1] == size(net.ω_i)[2] "external input size inconsistency"

    # update time
    net.time += dt
    BLAS.gemv!('N', dt, net.ω_f, net.output, 1.0 - dt, net.neuron_in) # feedback network dynamics
                                                                       # exponential decay of old signal
    BLAS.gemv!('N', dt, net.ω_i, ext_in, 1.0, net.neuron_in)           # input network dynamics

    # update the incoming signals for each neuron
    # TODO is there a way to avoid the allocation here?
    temp = net.ω_r * net.neuron_out            # intra (recurrent) network dynamics
    BLAS.axpy!(dt, temp, net.neuron_in)

    # update the outgoing signal for each neuron.
    net.neuron_out = net.α(net.neuron_in)

    # calculate network output
    # we do not use BLAS here, because net.output is really small so we do not gain anything
    net.output =  net.ω_o * net.neuron_out
    return net.output
end

function update!(net::SampleOutputNetwork, ext_in::Array{Float64}=zeros(size(net.ω_i)[2]))
    @assert size(ext_in)[1] == size(net.ω_i)[2] "external input size inconsistency"

    # update time
    net.time += dt
    BLAS.gemv!('N', dt, net.ω_f, net.output, 1.0 - dt, net.neuron_in) # feedback network dynamics
                                                                       # exponential decay of old signal
    BLAS.gemv!('N', dt, net.ω_i, ext_in, 1.0, net.neuron_in)           # input network dynamics

    # update the incoming signals for each neuron
    # TODO is there a way to avoid the allocation here?
    temp = net.ω_r * net.neuron_out            # intra (recurrent) network dynamics
    BLAS.axpy!(dt, temp, net.neuron_in)

    # update the outgoing signal for each neuron.
    net.neuron_out = net.α(net.neuron_in)

    # calculate network output
    # we do not use BLAS here, because net.output is really small so we do not gain anything
    @inbounds for i in length(net.output)
        net.output[i] = net.ω_o[i, 1] * net.neuron_out[net.output_neurons[1]]
        for j in 1:length(net.output_neurons)
            net.output[i] += net.ω_o[i, j] * net.neuron_out[net.output_neurons[j]]
        end
    end
    return net.output
end

#=net = Network(ω_r = [1 2; 3 4.])=#
