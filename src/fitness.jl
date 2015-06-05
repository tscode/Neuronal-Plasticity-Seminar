include("types.jl")

# this is the lowest level of fitness test: test a single network with learning rule for a single task
function test_fitness_for_task(net::AbstractNetwork, rule::AbstractRule, task::AbstractTask; learntime = 500, waittime = 1000, evaltime=500, adaptive=true )
  # generate the evaluator and the teacher
  # the parameters here are fixed for now: 1000 sec of learning, 100 steps window for evaluation
  evl     = Evaluator( 100, 0, net )
  reset(rule)                # reset the network
  teacher = Teacher( rule, evl, max_time = learntime, adaptive = adaptive)

  # now learn sth :)
  while !teacher.finished
    learn!(net, teacher, task)
  end

  # let some time pass
  # we continue to use evaluate
  evaluate(evl, task, waittime, rec=false) # TODO input

  # now reevaluate
  reset(evl)
  quality = evaluate(evl, task, evaltime, rec=false)

  return quality, evl.timeshift
end
