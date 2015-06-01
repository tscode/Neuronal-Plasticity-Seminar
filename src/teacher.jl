

type Teacher{R <: AbstractRule} <: AbstractTeacher
    rule::R
    period::Float64 # how often will learning occur in the simulation
    next::Float64   # next time of learning
    until::Float64  # time to stop learning altogether

    evl::AbstractEvaluator  # analyze the error
    adaptive_stepping::Bool
    can_adapt::Bool         # internal helper variable that decides whether learning rate adaption is possible
    precision::Float64      # threshold precision for the decision whether to change the learing rate

    function Teacher(rule::R, period::Real, next::Real, until::Real, evl::AbstractEvaluator, adaptive_stepping::Bool, precision::Float64 = 0.001)
        @assert period >= dt "the teaching period must be > dt = $dt"
        new(rule, period, next, until, evl, adaptive_stepping, false, precision)
    end
end

function Teacher(rule::AbstractRule, period::Real, next::Real, evl::AbstractEvaluator, until::Real=Inf, adaptive_stepping = false)
    return Teacher{typeof(rule)}(rule, period, next, until, evl, adaptive_stepping)
end


function synchronize!( teacher::Teacher, net::AbstractNetwork )
    teacher.next = net.time
end

function learn!( net::AbstractNetwork, teacher::Teacher, task::AbstractTask )
    @assert( net == teacher.evl.net )

     # adaptive stepping
     if teacher.adaptive_stepping && evaluate_step!(teacher.evl, task)
       # we need to make sure period does not grow to large. for now we just use an upper bound
       if get_current_score(teacher.evl) > (1-teacher.precision/2)  && teacher.can_adapt
         teacher.period += dt
         teacher.can_adapt = false
       elseif teacher.period > 2 * dt  && get_current_score(teacher.evl) < (1-teacher.precision)
         teacher.period /= 1.5
       end

     end

    if teacher.next <= teacher.until && teacher.next <= net.time + 1e-5
        teacher.next += teacher.period
        prepare_task!(task, net.time)
        update_weights!(teacher.rule, net, task)
        teacher.can_adapt = true # we want to have at least one learning step between subsequent learning rate increases
    end
end

