#
# INTERFACE
#

# Collection of interface functions -- not up to date?

function get_num_output(net::AbstractNetwork)
  error("get_num_output(AbstractNetwork) not implemented")
end

function get_num_input(net::AbstractNetwork)
  error("get_num_input(AbstractNetwork) not implemented")
end

# update the weigths according to rule
function update_weights!( rule::AbstractRule, net::AbstractNetwork )
  error("update_weights!(", typeof(rule), ", ", typeof(net), ") not implemented")
end

# prepare the task -- usually called by teacher
function set_time!( task::AbstractTask, time::Float64 )
  error("set_time!(", typeof(task), ", ", typeof(out), ")", "not implemented")
end

# compares out with the output the task desires
function compare_result( task::AbstractTask, out::Array{Float64} )  # returns Array{Float64}
  return out - get_expected(task)  # default implementation: difference between expected and generated
end

# checks the quality of the generated output
function eval_result( task::AbstractTask, out::Array{Float64} ) # returns Float64
  return norm( compare_result( task, out ) ) # default implementation: norm of the difference vector
end

# returns the expected output
function get_expected( task::AbstractTask )
  error("get expected(AbstractTask) not implemented")
end

# single teaching step
function learn!( net::AbstractNetwork, teacher::AbstractTeacher, task::AbstractTask )
  error("learn(", typeof(teacher), ", ", typeof(net), ", ", typeof(task), ")", "not implemented")
end

# generate network
function generate(generator::AbstractGenerator; seed::Int64=0)
  error("generate($(typeof(generator)), $(typeof(seed))) not implemented.")
end

function reset(rule::AbstractRule)
  error("rule(", typeof(rule), ") not implemented")
end

function export_params( generator::AbstractGenerator )
  error("export_params($(typeof(generator))) not implemented")
end

function import_params!( generator::AbstractGenerator, params )
  error("export_params($(typeof(generator)), $(typeof(params))) not implemented")
end

# convenience method for init of random number generators
function randseed()
	convert(Uint32, round(rand() * typemax(Uint32)))
end

function randseed(rng::AbstractRNG)
	convert(Uint32, round(rand(rng) * typemax(Uint32)))
end

