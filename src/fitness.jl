#
# FITNESS
#

# A measure for the success of a network
type SuccessRating <: AbstractSuccessRating
    quota::Float64      # relative number of successfull networks
    quality::Float64    # average quality of the successfull networks
    timeshift::Float64  # timeshift
    samples::Int        # number of samples used to calculate the rating
end


# this is the lowest level of fitness test: test a single network for a single task
function test_fitness_for_task( net::AbstractNetwork, rule::AbstractRule, 
                                task::AbstractTask;
                                learntime=500, waittime=1000 , 
                                evaltime=500,  adaptive=true , 
                                α=rule.α,      fname=""      )
  # generate the evaluator and the teacher
  # the parameters here are fixed for now: 1000 sec of learning, 100 steps window for evaluation
  if fname != ""
    recorder = Recorder()
  else
    recorder = REC
  end
  # prepare the learning process
  evl = Evaluator( 100, 0, net ) # produce an evaluator
  reset(rule, N = get_num_readout(net), α = α)  # reset the rule
  teacher = Teacher( rule, evl, max_time = learntime, adaptive = adaptive)

  # now learn sth :)
  while !teacher.finished
    learn!(net, teacher, task)
    # record in case that a filename was given
    if fname != ""
        record(recorder, 1, net.time)
        for i = 1:length(net.output)
           record(recorder, 1+i, net.output[1])
        end
    end
  end

  # let some time pass
  # we continue to use evaluate
  evaluate(evl, task, waittime, rec=fname != "", recorder=recorder) # TODO input
  # now reevaluate
  reset(evl)
  quality = evaluate(evl, task, evaltime, rec=fname != "", recorder=recorder)

  # save the data to file -- if given
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
function test_fitness_of_generator( gen::AbstractGenerator; rng::AbstractRNG=MersenneTwister(randseed()), 
                                    samples::Int = 25, threshold::Float64 = 0.95 )
  mean_q = 0.0
  mean_s = 0.0
  success = 0
  rule = ForceRule( α = 1/100 )
  for i = 1:samples
    task = make_periodic_function_task( gen.num_output, Function[], rng=rng )
    net = generate( gen, seed = randseed(rng) )
    q, s = test_fitness_for_task( net, rule, task )
    if q > threshold
      # rescale q relative to threshold
      mean_q += (q - threshold) / (1.0 - threshold)
      mean_s += s
      success += 1
    end
  end

  if success == 0
    return  SuccessRating(0,0,0, samples)
  end

  mean_q /= success
  mean_s /= success
  return SuccessRating(success/samples, mean_q, mean_s, samples)
end

# comparision of fitness results
function compare_fitness(v1::SuccessRating, v2::SuccessRating)
  # average error of v1 and v2. use err ~ 1/sqrt(N), because it is a counting process

  # probability, that v1 succeeds and v2 does not: v1.q * (1-v2.q)
  # directly decide who is better in that case:
  val = rand() # TODO use rng here
  if val < v1.quota * (1.0 - v2.quota) # v1 wins
    return true
  elseif val < v1.quota * (1.0 - v2.quota) + v2.quota * (1.0 - v1.quota) # v2 wins
    return false
  elseif val < v1.quota * (1.0 - v2.quota) + v2.quota * (1.0 - v1.quota) + (1.0 - v2.quota) * (1.0 - v1.quota)
    # both lose: we use the one with the better quota
    return v1.quota > v2.quota
  end

  # othwerwise, more elaborate mesures are required
  err = 0.5 / sqrt(v1.samples) + 0.5/sqrt(v2.samples)
  if v1.quota > v2.quota + err
    return true
  elseif v2.quota > v1.quota + err
    return false
  end

  # ok, almost identical success rate, now compare both success and quality
  return v1.quota + v1.quality > v2.quota + v2.quality
end
