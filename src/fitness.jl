include("types.jl")

# this is the lowest level of fitness test: test a single network with learning rule for a single task
function test_fitness_for_task(net::AbstractNetwork, rule::AbstractRule, task::AbstractTask; learntime = 500, waittime = 1000, evaltime=500, adaptive=true, α=rule.α, fname="")
  # generate the evaluator and the teacher
  # the parameters here are fixed for now: 1000 sec of learning, 100 steps window for evaluation
  if fname != "" 
    recorder = Recorder() 
  end
  evl     = Evaluator( 100, 0, net )
  reset(rule, N = net.num_neurons, α = α)                # reset the network
  teacher = Teacher( rule, evl, max_time = learntime, adaptive = adaptive)

  # now learn sth :)
  while !teacher.finished
    learn!(net, teacher, task)
    if fname != ""
        record(recorder, 1, net.time)
        for i = 1:length(net.output)
           record(recorder, 1+i, net.output[1])
        end
    end
  end

  # let some time pass
  # we continue to use evaluate
  evaluate(evl, task, waittime, rec=false) # TODO input

  # now reevaluate
  reset(evl)
  quality = evaluate(evl, task, evaltime, rec=false)

  if fname != ""
      data = zeros(size(recorder[1])[1], recorder.num_recs)
      for i in 1:length(recorder.num_recs)
          println(recorder[i])
          data[:, i] = recorder[i]
      end
      writedlm(fname, data)
  end

  return quality, evl.timeshift
end
