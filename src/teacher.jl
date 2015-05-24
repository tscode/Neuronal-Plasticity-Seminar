
type Teacher{R <: AbstractRule} <: AbstractTeacher
    rule::R
    period::Float64 # how often will learning occur in the simulation
    next::Float64   # next time of learning
    until::Float64  # time to stop learning altogether
    function Teacher(rule::R, period::Real, next::Real, until::Real)
        @assert period >= dt "the teaching period must be > dt = $dt"
        new(rule, period, next, until)
    end
end

function Teacher(rule::AbstractRule, period::Real, next::Real, until::Real=Inf)
    return Teacher{typeof(rule)}(rule, period, next, until)
end


function synchronize!( teacher::Teacher, net::AbstractNetwork )
    teacher.next = net.time
end

function learn!( net::AbstractNetwork, teacher::Teacher, task::AbstractTask )
    if teacher.next <= teacher.until && teacher.next <= net.time + 1e-5
        teacher.next += teacher.period
        prepare_task!(task, net.time)
        update_weights!(teacher.rule, net, task)
    end
end

