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
    params = AbstractParameter[ Parameter{Float64}( "percentage", 0.0, 1.0,              p        ) ,
                                Parameter{Float64}( "gain",       0.0, typemax(Float64), gain     ) ,
                                Parameter{Int}(     "size",       1,   typemax(Int),     size     ) ,
                                Parameter{Float64}( "feedback",   0.0, typemax(Float64), feedback ) ]
    # plug everthing in
    return new( params, num_input, num_output, num_readout, α )
  end
end

# "fake" constructor for SparseGenerator: use LR with full readout
function SparseFRGenerator(size::Int, p::Float64;
                              num_input::Integer=0, num_output::Integer=1,
                              gain::Real=1.2, feedback::Real=2, α::Function=tanh)
  return SparseLRGenerator(size, p, num_input=num_input, num_output=num_output,
                           num_readout = -1, gain = gain, feedback = feedback, α = α)
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
  num_readout = gen.num_readout < 0 ? N : gen.num_readout

  # internal connections: sparse, normal distributed
  ω_r = sprandn(rng, N, N, p) * gain / sqrt(N * p)
  # input weights
  ω_i = 1randn(rng, N, gen.num_input)
  # feedback connections: [-fb/2 ... fb/2]
  ω_f = feedback * (rand(rng, N, gen.num_output) - 0.5)
  # output (readout) weights
  ω_o = 1randn(rng, gen.num_output, num_readout)
  # initial values for the internal state and the output of the neurons
  neuron_in  = 0.5randn(rng, N)
  neuron_out = gen.α(neuron_in)
  # should readout be consistent with neuron_in?
  output = 2randn( rng, gen.num_output )

  # if we have full readout, use full readout network, else sparse readout
  # TODO, for more than x%, sparse readout actually hurts performance: find x
  #       and adapt the condition here <-- this should be fixed as LR networks
  #       are really fast now

  if num_readout >= N
    # generate a full readout network
    return Network{typeof(ω_r)}( ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out,
                                 output, gen.α, 0 )
  else
    # generate a genuinely limited readout network
    return LRNetwork{typeof(ω_r)}( ω_r, ω_i, ω_f, ω_o, neuron_in, neuron_out,
                                   output, num_readout, gen.α, 0 )
  end
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
