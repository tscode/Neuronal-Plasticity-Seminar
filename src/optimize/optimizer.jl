#
# OPTIMIZE - OPTIMIZER
#


abstract AbstractOptimizer{T}

# optimizer interface

function get_recorder(opt::AbstractOptimizer)
  return opt.recorder
end

function set_callback!(opt::AbstractOptimizer, callback::Function)
  opt.callback = callback
end

# simple default callback
function default_callback(opt::AbstractOptimizer, step::Integer)
  println("finished step $(step)")
end
