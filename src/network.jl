include("types.jl")

# generic network class
type Network{T1 <: AAF, T2 <: AAF, T3 <: AAF, T4 <: AAF} <: AbstractNetwork
    ω_r::T1    # weights_recurrent; for the recurrent neuron connections
    ω_i::T2    # weights_input; input->internal neurons
    ω_f::T3    # weights_feedback; output->internal neurons
    ω_o::T4        # weights internal neurons -> output

    #neurons::Vector{NeuronType}
    # maybe put this into NeuronType
    neuron_in::Vector{Float64}    # same length as neurons
    neuron_out::Vector{Float64}   # what the neurons fired last step
    readout::Vector{Float64}      # last output the network produced

    α::Function                   # mapping the neuron input to output, α for "activation"

    time::Float64


    # "internal" constructor -- only this one can then be called in programs
    function Network( ω_r::T1, ω_i::T2, ω_f::T3, ω_o::T4, neuron_in::Vector{Float64},
                      neuron_out::Vector{Float64}, readout::Vector{Float64}, α::Function, time::Float64 )
        # consistency checks
        # First, all dimensions
        @assert size(ω_r)[1] == size(ω_r)[2]      == size(ω_i)[1]       == size(ω_f)[1] ==
                size(ω_o)[2] == length(neuron_in) == length(neuron_out) "Inconsistent number of internal neurons"

        @assert size(ω_o)[1] == length(readout) "Inconsistent number of readout neurons"

        # create an instance, specialized on the given types
        return new(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, readout, α, time)
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
                   readout::Vector{Float64}    = zeros(size(ω_o)[1]),
                   time::Real = 0.
                )
    return Network{typeof(ω_r), typeof(ω_i), typeof(ω_f), typeof(ω_o)}(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, readout, α, time)
end


function update!(net::Network, ext_in::Array{Float64}=zeros(size(net.ω_i)[2]))
    # update time
    net.time += dt

    # update the incoming signals for each neuron
    net.neuron_in += (- net.neuron_in                 # exponential decay of old signal
                      + net.ω_r * net.neuron_out      # intra (recurrent) network dynamics
                      + net.ω_i * ext_in              # input network dynamics
                      + net.ω_f * net.readout         # feedback network dynamics
                     ) * dt                           # extremly simple numerical integration

    # update the outgoing signal for each neuron.
    net.neuron_out = net.α(net.neuron_in)

    # calculate network output
    net.readout = net.ω_o * net.neuron_out
    return net.readout
end


#=net = Network(ω_r = [1 2; 3 4.])=#
