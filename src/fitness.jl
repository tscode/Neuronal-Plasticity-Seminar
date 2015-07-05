#
# FITNESS
#

import optimize.AbstractRating
import optimize.get_value

# A measure for the success of a network
type SuccessRating <: AbstractRating
    quota::Float64      # relative number of successfull networks
    quality::Float64    # average quality of the successfull networks
    timeshift::Float64  # timeshift
    samples::Int        # number of samples used to calculate the rating
end

# Sum of two success ratings is their weighted average
function +(A::SuccessRating, B::SuccessRating)
  va = Float64[A.quota, A.quality, A.timeshift]
  vb = Float64[B.quota, B.quality, B.timeshift]
  r = (va*A.samples + vb*B.samples)/(A.samples + B.samples)
  return SuccessRating( r[1], r[2], r[3], A.samples + B.samples )
end

function get_value(v::SuccessRating)
  return v.quota
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

# test the fitness of a generator in a given environment
function fitness_in_environment( gen::AbstractGenerator; samples::Int = 25,
                                 rng::AbstractRNG=MersenneTwister(randseed()),
                                 env::AbstractEnvironment=default_environment(),
                                 threshold::Float64 = 0.95, adaptive::Bool=true )
    # variables for the mean quality and the timeshifts of the samples / phenotypes
    mean_qual  = 0.
    mean_shift = 0.
    # number of successful samples / phenotypes
    num_success = 0.
    # empty rule; what to do with α?
    rule = ForceRule( α = 1/100 )
    # how many challenges may occur in the environment
    num_challenges = length(env.challenges)
    # now let the epic fight for predomination of phenotypes begin. Go
    # through the samples, choose challenges, get concrete tasks and use
    # these to evaluate the performance / fitness
    for i in 1:samples
      # the challenge number for this sample
      j = (i-1) % (num_challenges) + 1
      # the chosen challenge
      ch = env.challenges[j]
      # the specific task for this challenge
      task = get_task(ch, rng=rng)
      # generate a network that is specialized for the right number of
      # output/input channels
      net = generate( gen, seed = randseed(rng),
                      num_output = length(task.ofuncs),
                      num_input = length(task.ifuncs) )
      # perform the actual test
      qual, shift = test_fitness_for_task( net, rule, task, adaptive=adaptive )
      #
      if qual > threshold
        # linearly rescale quality to region [threshold, 1]
        mean_qual   += (qual - threshold) / (1.0 - threshold)
        mean_shift  += shift
        num_success += 1
      end
  end
  # if no sample succeded
  if num_success == 0
    return SuccessRating(0, 0, 0, samples)
  end
  # if at least one sample succeded
  mean_qual  /= num_success
  mean_shift /= num_success
  #
  return SuccessRating( num_success/samples, mean_qual, mean_shift, samples )
end

# test fitness for a generator
function test_fitness_of_generator( gen::AbstractGenerator; samples::Int = 25,
                                    rng::AbstractRNG=MersenneTwister(randseed()),
                                    env::AbstractEnvironment=default_environment(),
                                    threshold::Float64 = 0.95, adaptive::Bool=true )
  mean_q = 0.0
  mean_s = 0.0
  success = 0
  rule = ForceRule( α = 1/100 )
  for i in 1:samples
    net = generate( gen, seed = randseed(rng) )
    task = make_periodic_function_task( get_num_output(net), Function[], rng=rng )
    q, s = test_fitness_for_task( net, rule, task, adaptive=adaptive )
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
function compare_fitness(v1::SuccessRating, v2::SuccessRating, rng::AbstractRNG)
  # average error of v1 and v2. use err ~ 1/sqrt(N), because it is a counting process

  # probability, that v1 succeeds and v2 does not: v1.q * (1-v2.q)
  # directly decide who is better in that case:
  val = rand(rng)
  if val < (p0 = v1.quota * (1.0 - v2.quota)) # v1 wins
    return true
  elseif val < (p0 += v2.quota * (1.0 - v1.quota)) # v2 wins
    return false
  elseif val < (p0 += (1.0 - v2.quota) * (1.0 - v1.quota)) # both lose
    # both lose: we use the one with the better quota
    return v1.quota > v2.quota
  end

  # ok, almost identical success rate, now compare both success and quality
  return 2*v1.quota + v1.quality > 2*v2.quota + v2.quality
end
