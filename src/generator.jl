include("types.jl")

type SparseMatrixGenerator <: AbstractGenerator
	p::Float64			  # percentage of edges taken
	gain::Real			  # gain factor for edge strength
	size::Int			    # size of the network
	num_input::Int64		# number of input channels
	num_output::Int64		# number of output channels
	feedback::Real		# strength of feedback connections

  function SparseMatrixGenerator(size::Int, p::Float64; num_input=0, num_output=1, gain::Real=1.2, feedback::Real=2)
    @assert 0 < p <= 1 "p is a connection probability, thus 0 < p <= 1"
    return new(p, gain, size, num_input, num_output, feedback)
  end
end

function SparseMatrixGenerator(size, p; num_input=0, num_output=1, gain=1.2, feedback=2)
  return SparseMatrixGenerator(size, p, num_input=num_input, num_output=num_output, gain=gain, feedback=feedback)
end

function generate(generator::SparseMatrixGenerator, seed::Int64)
	# initialize random by seed
	srand(seed)

	# convenience variable
	N = generator.size

	# internal connections: sparse, normal distributed
	ω_r = sprandn(N, N, generator.p)*generator.gain/sqrt(N * generator.p)
	# feedback connections: [-1 .. 1]
	ω_f = generator.feedback * (rand(N, generator.num_output) - 0.5)
	# output (readout) weights.
	ω_o = 1randn(generator.num_output, N)
	# input weights
	ω_i = 1randn(N, generator.num_input)

	neuron_in = 0.5randn(N)

	# should readout be consisten with neuron_in?
	readout = 2randn( generator.num_output )

	# generate the network
	net     = NetworkTest( ω_r = ω_r, ω_f = ω_f, neuron_in = neuron_in, readout = readout, ω_o = ω_o )
end
