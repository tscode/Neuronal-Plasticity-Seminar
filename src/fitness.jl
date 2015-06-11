include("types.jl")

# this is the lowest level of fitness test: test a single network with learning rule for a single task
function test_fitness_for_task(net::AbstractNetwork, rule::AbstractRule, task::AbstractTask; 
         learntime = 500, waittime = 1000, evaltime=500, adaptive=true, α=rule.α, fname="")
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
  evaluate(evl, task, waittime, rec=true, recorder=recorder) # TODO input

  # now reevaluate
  reset(evl)
  quality = evaluate(evl, task, evaltime, rec=true, recorder=recorder)

  if fname != ""
      data = zeros(size(recorder[1])[1], recorder.num_recs)
      for i in 1:recorder.num_recs
          data[:, i] = recorder[i]
      end
      writedlm(fname, data)
  end

  return quality, evl.timeshift
end


# test fitness for a generator
function test_fitness_of_generator(gen::AbstractGenerator; rnd::AbstractRNG=MersenneTwister(), samples = 25, threshold = 0.95)
  mean_q = 0.0
  mean_s = 0.0
  success = 0
  rule = ForceRule( gen.size, 0.1 )
  for i = 1:samples
    task = make_periodic_function_task(gen.num_output, [x->0], rnd)
    net = generate( gen, int(rand()*10000))
    q, s = test_fitness_for_task( net, rule, task )
    if q > threshold
      # rescale q reltive to threshold
      mean_q += (q - threshold) / (1.0 - threshold)
      mean_s += s
      success += 1
    end
  end

  mean_q /= success
  mean_s /= success
  return success/samples, mean_q, mean_s
end

# comparision of fitness results
function compare_fitness(v1, v2)
  if v1[1] > v2[1] + 0.05
    return true
  elseif v2[1] > v1[1] + 0.05
    return false
  end

  # ok, almost identical success rate, now compare both success and quality
  return v1[1] + v1[2] > v2[1] + v2[2]
end


