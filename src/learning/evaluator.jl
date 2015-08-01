#
# EVALUATOR
#

abstract AbstractEvaluator

# concrete evaluator type used to grade the performance of networks
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
function evaluate_step!(evl::Evaluator, task::AbstractTask, allow_shift::Bool=true) # ::Bool
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
    calculate_correlation!(evl, allow_shift)
    return true
  end
  return false
end

function calculate_correlation!( evl::Evaluator, allow_shift = true )
  @assert evl.T == evl.chunksize + 1 "trying to calculate correlation before chunk was filled"
  # now evaluate the collected chunk.
  # first, we remove a costant phase shift. to do that,
  # we look at the crosscorrelation of expected and received
  # and choose Δt such that it is maximized

  mshift =  div(evl.chunksize, 10)
  if !allow_shift
    mshift = 0
  end

  ΔT, corr = best_shift(evl.received, evl.expected, mshift)

  # just nice variable names
  evl.timeshift   += ΔT * dt
  evl.last_result  = corr
  evl.sumcor      += evl.last_result
  evl.chunkcount  += 1

  # reset chunks
  # copy right boundary to left boundary
  evl.received[1:mshift] = evl.received[end-mshift+1:end]
  evl.expected[1:mshift] = evl.expected[end-mshift+1:end]
  evl.T = 1 + mshift
end

function evaluate(evl::Evaluator, task::AbstractTask, duration::Real; rec::Bool=false, recorder=REC)
  start_time = evl.net.time
  while evl.net.time < start_time + duration
    prepare_task!(task, evl.net.time  + dt, false) # non deterministic: allows noise in input
    update!(evl.net, get_input(task))
    evaluate_step!(evl, task)
    if rec
      record(recorder, 1, evl.net.time)
      record(recorder, 2, evl.net.time - evl.timeshift)
      record(recorder, 3, get_expected(task)[1])
      for i = 1:length(evl.net.output)
        record(recorder, 3+i, evl.net.output[i])
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


####################################################################
#            helpers for time-shift detection                      #
####################################################################

# TODO do these functions belong into util

function mxcorr{T}(a::Array{T}, b::Array{T}, max_shift::Integer)
  @assert( length(a) <= length(b) )
  @assert( max_shift <= length(b) - length(a))

  len::Integer = length(a)
  dtime::Integer = 0     # shift for maximum cross correlation
  mxsum::Float64 = -Inf  # maximum value of cross correlation

  for ΔT = 0:max_shift
    summed::Float64 = 0.0
    bnorm::Float64 = 0.0
    for i = 1:len
      #println(i, i+ΔT)
      summed += sum(a[i] .* b[i + ΔT])
      bnorm += sum(b[i + ΔT] .* b[i + ΔT])
    end
    summed /= sqrt(bnorm)
    if summed > mxsum
      mxsum = summed
      dtime = ΔT
    end
  end

  return dtime, mxsum
end

# returns best timeshift and correlation at best timeshift.
function best_shift{T}(a::Array{T}, b::Array{T}, boundary::Integer)
  # take the inner part of a
  kernel = a[boundary+1:length(a)-boundary]
  knorm = norm(kernel)
  if knorm == 0
    return 0, 0
  end
  shift, corr = mxcorr(kernel, b, 2*boundary)
  return -(shift - boundary), corr / knorm
end

# test code: when this function es executed, no asserts should fire :)
function test_mxcorr()
  # this is the cricical situation
  for ts = -5:1:5
    data = [cos((x)/100) for x in 0:99]
    ref =  [cos((x+ts)/100) for x in 0:99]
    s, mx = best_shift(data, ref, 10)
    #writedlm("xcorr2", [dc data ref])
    @assert( s == ts, "$(s) timeshift is wrong, expected $(ts)" )
  end
end
