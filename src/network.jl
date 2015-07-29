#
# NETWORK
#

abstract AbstractNetwork

# LRNetwork: Limited Readout: don't use all neurons as readout neurons
type LRNetwork{T <: AbstractArray{Float64, 2}} <: AbstractNetwork
  # weights
  ω_r::T                        # recurrent weigthts
  ω_i::Matrix{Float64}          # weights used for the external input
  ω_f::Matrix{Float64}          # feedback weights
  ω_o::Matrix{Float64}          # weights used to create the readout
  
  # neurons
  neuron_in::Vector{Float64}    # same length as neurons
  neuron_out::Vector{Float64}   # what the neurons fired last step
  output::Vector{Float64}       # last output the network produced

  # misc
  α::Function                   # activation function, convert neuron_in to neuron_out
  time::Float64                 # current time
  num_readout::Int              # number of activated readout neurons, <= num_neurons
  num_neurons::Int              # number of recurrent neurons; convenience

  function LRNetwork( ω_r::T, ω_i::Matrix{Float64}, ω_f::Matrix{Float64}, ω_o::Matrix{Float64},
                      neuron_in::Vector{Float64},   neuron_out::Vector{Float64}, 
                      output::Vector{Float64},      num_readout::Int, 
                      α::Function,                  time::Real )

    # consistency checks
    @assert size(ω_r)[1] == size(ω_r)[2]      == size(ω_i)[1]       == size(ω_f)[1] ==
            length(neuron_in) == length(neuron_out) "inconsistent number of internal neurons"

    @assert size(ω_o)[1] == length(output) "inconsistent number of output channels"
    @assert size(ω_o)[2] == num_readout "inconsistent number of output neurons"
    @assert num_readout <= size(ω_r)[1] "more readout neurons than total number of neurons specified"
    #
    return new(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, output, α, time, num_readout, size(ω_r)[1])
  end # function Network
end # type LRNeurons





# generic network class
type Network{T1 <: AbstractArray{Float64, 2}} <: AbstractNetwork
  ω_r::T1    # weights_recurrent; for the recurrent neuron connections
  ω_i::Matrix{Float64}   # weights_input; input->internal neurons
  ω_f::Matrix{Float64}   # weights_feedback; output->internal neurons
  ω_o::Matrix{Float64}   # weights internal neurons -> output

  #neurons::Vector{NeuronType}
  # maybe put this into NeuronType
  neuron_in::Vector{Float64}    # same length as neurons
  neuron_out::Vector{Float64}   # what the neurons fired last step
  output::Vector{Float64}       # last output the network produced

  α::Function                   # mapping the neuron input to output, α for "activation"

  time::Float64                 # current time
  num_neurons::Int              # total number of "recurrent" neurons

  # constructor
  function Network( ω_r::T1, ω_i::Matrix{Float64}, ω_f::Matrix{Float64}, 
                    ω_o::Matrix{Float64}, neuron_in::Vector{Float64}, neuron_out::Vector{Float64}, 
                    output::Vector{Float64}, α::Function, time::Real )
    # consistency checks
    @assert size(ω_r)[1] == size(ω_r)[2]      == size(ω_i)[1]       == size(ω_f)[1] ==
            size(ω_o)[2] == length(neuron_in) == length(neuron_out) "Inconsistent number of internal neurons"

    @assert size(ω_o)[1] == length(output) "Inconsistent number of output neurons"

    # create an instance, specialized on the given types
    return new(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, output, α, time, size(ω_r)[1])
  end # function Network

end # type Network


# update routines that simulate the time development of the network
function update!(net::Network, ext_in::Array{Float64}=zeros(size(net.ω_i)[2]))
    @assert size(ext_in)[1] == size(net.ω_i)[2] "external input size inconsistency"
    # update time
    net.time += dt
    # update the incoming signals for each neuron
    BLAS.gemv!( 'N', dt, net.ω_f, net.output, 1.0 - dt, net.neuron_in )
    BLAS.gemv!( 'N', dt, net.ω_i, ext_in, 1.0, net.neuron_in )
    A_mul_B!( dt, net.ω_r, net.neuron_out, 1.0, net.neuron_in )

    # update the outgoing signal for each neuron.
    net.neuron_out = net.α(net.neuron_in)

    # calculate network output
    # we do not use BLAS here, because net.output is really small so we do
    # not gain anything the overhead of calling seems to exceed memory
    # allocation
    net.output =  net.ω_o * net.neuron_out
    return net.output
end

function update!(net::LRNetwork, ext_in::Array{Float64}=zeros(size(net.ω_i)[2]))
    @assert size(ext_in)[1] == size(net.ω_i)[2] "external input size inconsistency"
    # update time
    net.time += dt
    # update the incoming signals for each neuron
    BLAS.gemv!('N', dt, net.ω_f, net.output, 1.0 - dt, net.neuron_in) 
    BLAS.gemv!('N', dt, net.ω_i, ext_in, 1.0, net.neuron_in)
    A_mul_B!( dt, net.ω_r, net.neuron_out, 1.0, net.neuron_in )

    # update the outgoing signal for each neuron.
    net.neuron_out = net.α(net.neuron_in)

    # calculate network output
    # we do not use BLAS here, because net.output is really small so we do
    # not gain anything the overhead of calling seems to exceed memory
    # allocation
    net.output = net.ω_o * net.neuron_out[1:net.num_readout]
    return net.output
end

get_num_output(net::Network) = length(net.output)
get_num_output(net::LRNetwork) = length(net.output)

get_num_readout(net::AbstractNetwork) = net.num_neurons
get_num_readout(net::LRNetwork) = net.num_readout
