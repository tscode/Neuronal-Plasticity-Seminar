#
# GENERATOR
#


# introduce parameter type that is used for genetic modifications
# each parameter corresponds loosely to one gene that can be modified
# by reproduction and mutation
type Parameter{T} <: AbstractParameter
    name::ASCIIString
    min::T
    max::T
    val::T
end


## generators for the type 'Network' ##
type SparseGenerator <: AbstractGenerator
  p::Float64			# percentage of edges taken
  gain::Float64			# gain factor for edge strength
  size::Int			    # size of the network
  num_input::Int64		# number of input channels
  num_output::Int64		# number of output channels
  feedback::Float64		# strength of feedback connections
  α::Function           # activation function

  # default constructor
  function SparseGenerator( size::Int, p::Float64; 
                            num_input::Integer=0, num_output::Integer=1, 
                            gain::Real=1.2, feedback::Real=2, α::Function=tanh )
    # consistency checks
    @assert 0 < p <= 1 "p is a connection probability, thus 0 < p <= 1"
    return new( p, gain, size, num_input, num_output, feedback, α )
  end
end


# generate function used to actually create networks; realization of a random network
function generate(generator::SparseGenerator; seed::Integer = randseed())  ## TO BE DEPRECATED
	# initialize an rng by the given seed
	rng = MersenneTwister(seed)
	# convenience variable
	N = generator.size
	# internal connections: sparse, normal distributed
	ω_r = sprandn(rng, N, N, generator.p) * generator.gain / sqrt(N * generator.p)
	# input weights
	ω_i = 1randn(rng, N, generator.num_input)
	# feedback connections: [-fb/2 ... fb/2]
	ω_f = generator.feedback * (rand(rng, N, generator.num_output) - 0.5)
	# output (readout) weights
	ω_o = 1randn(rng, generator.num_output, N)
    # initial values for the internal state and the output of the neurons
	neuron_in  = 0.5randn(rng, N)
    neuron_out = generator.α(neuron_in)
	# should readout be consisten with neuron_in?
	output = 2randn( rng, generator.num_output )
	# generate the network
    return Network{typeof(ω_r)}( ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, output, generator.α, 0 )
end

function export_params( generator::SparseGenerator)   ## TO BE DEPRECATED
  D::Dict{String, Tuple} = Dict{String, Tuple}()
  D["percentage"] = (0.0, 1.0, generator.p)
  D["gain"] = (0.0, 4.0, generator.gain)           # !TODO is this a good maximum? maybe we should specify a distribution
  D["size"] = (max(0, generator.size - 10), max(0, generator.size + 10), generator.size)          # this limits size to close to old size
                                                   # changes out of nothing
  D["feedback"] = (0.0, 4.0, generator.feedback)
  return D
end

function import_params!(generator::SparseGenerator, params::Dict{String, Tuple})  ## TO BE DEPRECATED
  generator.p = params["percentage"][3]
  generator.gain = params["gain"][3]
  generator.size = params["size"][3]
  generator.feedback = params["feedback"][3]
end



# generator for the type 'LRNetwork'
type SparseLRGenerator <: AbstractGenerator
  # parameters that may be altered by mutation
  params::Vector{AbstractParameter}  
  # must contain 1: percentage
  #              2: gain
  #              3: size
  #              4: feedback

  num_input::Int64		# number of input channels
  num_output::Int64		# number of output channels
  num_readout::Int64    # number of neurons used to produce the output
  α::Function           # activation function

  # default constructor
  function SparseLRGenerator( size::Int, p::Float64; 
                              num_input::Integer=0, num_output::Integer=1, 
                              num_readout::Integer=div(size,2), 
                              gain::Real=1.2, feedback::Real=2, α::Function=tanh )
    # some checks
    @assert 0 < p <= 1 "p is a connection probability, thus 0 < p <= 1"
    # create the vector of parameters to be given to the generator
    params = AbstractParameter[ Parameter{Float64}( "percentage", 0.0, 1.0,  p        ) ,
                                Parameter{Float64}( "gain",       0.0, 4.0,  gain     ) ,
                                Parameter{Int}(     "size",       1,   5000, size     ) ,
                                Parameter{Float64}( "feedback",   0.0, 4.0,  feedback ) ]
    # plug everthing in                            
    return new( params, num_input, num_output, num_readout, α )
  end
end


# Generate a concrete, random network (phenotype) using the generator (genotype)
function generate(gen::SparseLRGenerator; seed::Integer = randseed())   ## TO BE GENERALIZED
	# initialize an rng by the given seed
	rng = MersenneTwister(seed)
	# convenience variables
    p        = gen.params[1].val
    gain     = gen.params[2].val
	N        = gen.params[3].val
    feedback = gen.params[4].val
	# internal connections: sparse, normal distributed
	ω_r = sprandn(rng, N, N, p) * gain / sqrt(N * p)
	# input weights
	ω_i = 1randn(rng, N, gen.num_input)
	# feedback connections: [-fb/2 ... fb/2]
	ω_f = feedback * (rand(rng, N, gen.num_output) - 0.5)
	# output (readout) weights
	ω_o = 1randn(rng, gen.num_output, gen.num_readout)
    # initial values for the internal state and the output of the neurons
	neuron_in  = 0.5randn(rng, N)
    neuron_out = gen.α(neuron_in)
	# should readout be consistent with neuron_in?
	output = 2randn( rng, gen.num_output )
    # neurons 1 to generator.num_readout shall be used for the readout
    output_neurons = collect(1:gen.num_readout)
	# generate the network
    return LRNetwork{typeof(ω_r)}( ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out, 
                                   output, output_neurons, gen.α, 0 )
end


# allow the parameters to be exported
function export_params( gen::SparseLRGenerator )  ## TO BE GENERALIZED
  return deepcopy(gen.params)
end

# import parameters in a network
function import_params!(gen::SparseLRGenerator, params::Vector{AbstractParameter})  ## TO BE GENERALIZED
  # check if the format of the parameters to be imported is suitable
  @assert length(params) == length(gen.params) "wrong length of vector of parameters"
  for i in 1:length(params)
      @assert gen.params[i].name == params[i].name "parameters to be imported do not fit"
  end
  # if it is then hand over a copy to the generator
  gen.params = deepcopy(params)
end
