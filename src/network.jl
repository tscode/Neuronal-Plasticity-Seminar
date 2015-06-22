#
# NETWORK
#

# LRNetwork: Limited Readout: don't use all neurons as readout neurons
type LRNetwork{T <: AAF} <: AbstractNetwork
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
  output_neurons::Vector{Int}   # vector of indices that are used for the readout
  α::Function                   # activation function, convert neuron_in to neuron_out
  time::Float64                 # current time
  num_neurons::Int              # number of recurrent neurons; convenience

  function LRNetwork( ω_r::T, ω_i::Matrix{Float64}, ω_f::Matrix{Float64}, ω_o::Matrix{Float64},
                      neuron_in::Vector{Float64},   neuron_out::Vector{Float64}, 
                      output::Vector{Float64},      output_neurons::Vector{Int}, 
                      α::Function,                  time::Real )

    # consistency checks
    @assert size(ω_r)[1] == size(ω_r)[2]      == size(ω_i)[1]       == size(ω_f)[1] ==
            length(neuron_in) == length(neuron_out) "inconsistent number of internal neurons"

    @assert size(ω_o)[1] == length(output) "inconsistent number of output channels"
    @assert size(ω_o)[2] == length(output_neurons) "inconsistent number of output neurons"

    # ensure that all neuron indices occuring in 'output_neurons'
    # are unique and between 1 and 'num_neurons'
    last = 0
    for index in output_neurons
      @assert index > last "index vector 'output_neurons' must be strictly increasing"
      last = index
    end
    @assert last <= size(ω_r)[1] "'output_neurons' contains index which is higher than 'num_neurons'"
    return new(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, output, output_neurons, α, time, size(ω_r)[1])
  end # function Network
end # type LRNeurons





# generic network class
type Network{T1 <: AAF} <: AbstractNetwork
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


# "external" constructor so that one does not always have to type the parameter type stuff
# not important since networks will be generated by generators <=> genotypes
function NetworkTest(; ω_r = error("internal weight matrix must be given"),   ## TO BE DEPRECATED
                   ω_i = randn(size(ω_r)[1],1),            # weights_input; input->internal neurons
                   ω_f = randn(size(ω_r)[1],1),            # weights_feedback; output->internal neurons
                   ω_o = randn(1,size(ω_r)[2]),            # weights internal neurons -> output

                   α::Function = tanh,
                   neuron_in::Vector{Float64}  = randn(size(ω_r)[2]),
                   neuron_out::Vector{Float64} = α(neuron_in),
                   output::Vector{Float64}    = zeros(size(ω_o)[1]),
                   time::Real = 0.
                )
    return Network{typeof(ω_r)}(ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, output, α, time)
end


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
    # we do not use BLAS here, because net.output is really small so we do not gain anything
    # the overhead of calling seems to exceed mem allocation
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
        for j in 2:length(net.output_neurons)
            net.output[i] += net.ω_o[i, j] * net.neuron_out[net.output_neurons[j]]
        end
    end
    return net.output
end

get_num_output(net::Network) = length(net.output)
get_num_output(net::LRNetwork) = length(net.output)

get_num_readout(net::AbstractNetwork) = net.num_neurons
get_num_readout(net::LRNetwork) = length(net.output_neurons)
