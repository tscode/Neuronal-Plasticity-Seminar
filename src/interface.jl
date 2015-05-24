
## interfaces

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
  error("compare_result(", typeof(task), ", ", typeof(out), ")", "not implemented")
end

# checks the quality of the generated output
function eval_result( task::AbstractTask, out::Array{Float64} ) # returns Float64
  return norm( compare_result( task, out ) )
end

# single teaching step
function teach!( teacher::AbstractTeacher, net::AbstractNetwork, task::AbstractTask )
  error("teach(", typeof(teacher), ", ", typeof(net), ", ", typeof(task), ")", "not implemented")
end

# convenience layer if we only want do develop the system 
#=function learn_until!( teacher::AbstractTeacher, net::AbstractNetwork, task::AbstractTask, stop_time::Float64 )=#
    #=while net.time < stop_time=#
        #=teach!(teacher, net, task)=#
    #=end=#
#=end=#

