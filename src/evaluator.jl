include("types.jl")
include("recorder.jl")

type Evaluator <: AbstractEvaluator
  # configuration
  chunksize::Int
  net::AbstractNetwork

  # error results
  timeshift::Float64
  last_result::Float64

  # internal workings
  expected::Array{Float64}
  received::Array{Float64}
  T::Int # iterator through the expected, received Arrays. 1 <= T <= chunksize
  sumcor::Float64
  chunkcount::Int

  function Evaluator(chunksize::Int, timeshift::Real, net::AbstractNetwork)
    expected = zeros( chunksize, get_num_output(net) )
    received = zeros( chunksize, get_num_output(net) )
    new(chunksize, net, timeshift, -1, expected, received, 1, 0.0, 0)
  end
end

# this function does not advance network time
# returns true is we have collected a full chunk and updated the error
function evaluate_step!(evl::Evaluator, task::AbstractTask)
  # update task for currently needed time
  old_time = task.time
  old_det  = task.deterministic
  prepare_task!(task, evl.net.time - evl.timeshift, true)

  evl.expected[evl.T,:] = get_expected(task)
  evl.received[evl.T,:] = evl.net.output

  # reset task to old time
  prepare_task!(task, old_time, old_det)

  evl.T += 1
  if evl.T > evl.chunksize
    calculate_correlation!(evl)
    return true
  end
  return false
end

function calculate_correlation!( evl::Evaluator )
  @assert evl.T == evl.chunksize + 1 "trying to calculate correlation before chunk was filled"
  # now evaluate the collected chunk.
  # first, we remove a costant phase shift. to do that, we look at the crosscorrelation of expected and received
  # and choose Δt such that it is maximized
  mxsum = -inf(1.0)
  dtime = 0
  recvn = norm(evl.received)
  # in case the network died down, we can skip all the computations (and avoid NaN)
  if recvn == 0
     # dead network counts as fully failed
    evl.last_result = 0
    evl.chunkcount += 1
    evl.T = 1
  end
  for ΔT = -div(evl.chunksize, 10):div(evl.chunksize, 10)
    summed = 0.0
    for i = 1+max(0,-ΔT):evl.chunksize-max(0, ΔT)
      #println(i, i+ΔT)
      summed += sum(evl.expected[i] .* evl.received[i + ΔT])
    end
    if summed > mxsum
      mxsum = summed
      dtime = ΔT
    end
  end

  # just nices variable names
  evl.timeshift += dtime * dt
  evl.last_result = mxsum / norm(evl.expected) / recvn
  evl.sumcor += evl.last_result
  evl.chunkcount += 1

  # reset chunks
  evl.T = 1
end

function evaluate(evl::Evaluator, task::AbstractTask, duration::Real; rec::Bool=false, recorder=REC)
  start_time = evl.net.time
  while evl.net.time < start_time + duration
    prepare_task!(task, evl.net.time  + dt, false) # non deterministic: allows noise in input
    update!(evl.net, get_input(task))
    evaluate_step!(evl, task)
    if rec
      record(recorder, 1, evl.net.time)
      for i = 1:length(evl.net.output)
        record(recorder, 1+i, evl.net.output[i])
      end
    end
  end

  return evl.sumcor / evl.chunkcount
end

function get_current_score(evl::Evaluator)
  return evl.last_result
end

function get_accumulated_score(evl::Evaluator)
  return evl.sumcor / evl.chunkcount
end

function reset(evl::Evaluator)
  evl.T = 1
  # leave timeshift intact?
  evl.last_result = -1
  evl.sumcor = 0
  evl.chunkcount = 0
end
