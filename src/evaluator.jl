include("types.jl")
include("recorder.jl")

type Evaluator
end

function evaluate(evl::Evaluator, net::AbstractNetwork, task::AbstractTask, duration::Real)
  start_time = net.time
  total_error = 0.0
  step_count = 0
  while net.time < start_time + duration
    update!(net)
    prepare_task!(task, net.time)
    err = compare_result(task, net.output)
    total_error += norm(err)
    step_count += 1
  end

  return total_error / step_count
end
