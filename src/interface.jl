
## interfaces
# network interface
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

# sets the task in deterministic/indeterministic mode.
function set_deterministic!( task::AbstractTask, det::Bool )
  error("set_deterministic(AbstactTask, Bool) not implemented")
end

# single teaching step
function learn!( net::AbstractNetwork, teacher::AbstractTeacher, task::AbstractTask )
  error("learn(", typeof(teacher), ", ", typeof(net), ", ", typeof(task), ")", "not implemented")
end

# generate network
function generate(generator::AbstractGenerator, seed::Int64)
  error("generate(", typeof(generator), "Int64) not implemented")
end
# convenience layer if we only want do develop the system
#=function learn_until!( teacher::AbstractTeacher, net::AbstractNetwork, task::AbstractTask, stop_time::Float64 )=#
    #=while net.time < stop_time=#
        #=teach!(teacher, net, task)=#
    #=end=#
#=end=#

