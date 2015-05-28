include("types.jl")
include("recorder.jl")

type Evaluator
  chunksize::Int
  timeshift::Float64
end

function evaluate(evl::Evaluator, net::AbstractNetwork, task::AbstractTask, duration::Real)
  start_time = net.time
  total_corr = 0.0
  step_count = 0
  while net.time < start_time + duration
    expected = zeros( evl.chunksize, size(net.output,1) )
    received = zeros( evl.chunksize, size(net.output,1) )
    @rec net.time net.output[1] for i = 1:evl.chunksize
      update!(net)
      prepare_task!(task, net.time - evl.timeshift)
      expected[i,:] = get_expected(task)
      received[i,:] = net.output
    end

    # now evaluate the collected chunk.
    # first, we remove a costant phase shift. to do that, we look at the crosscorrelation of expected and received
    # and choose Δt such that it is maximized
    mxsum = -inf(1.0)
    dtime = 0
    for ΔT = -div(evl.chunksize, 10):div(evl.chunksize, 10)
        summed = 0.0
        for i = 1+max(0,-ΔT):evl.chunksize-max(0,ΔT)
            #println(i, i+ΔT)
            summed += sum(expected[i] .* received[i + ΔT])
        end
        if summed > mxsum
            mxsum = summed
            dtime = ΔT
        end
    end

    # just nices variable names
    evl.timeshift += dtime * dt
    total_corr += mxsum / norm(expected) / norm(received)
    step_count += 1
  end

  return total_corr / step_count
end
