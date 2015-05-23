
type Teacher{R <: AbstractRule} <: AbstractTeacher
    rule::R
    period::Float64 # how often will learning occur in the simulation
    last::Float64 # last time of learning
    function Teacher(rule::R, period::Real, last::Real)
        new(rule, period, last)
    end
end

function Teacher(rule::AbstractRule, period::Real, last::Real=-Inf)
    Teacher{typeof(rule)}(rule, period, last)
end


function teach!( teacher::Teacher, net::AbstractNetwork, task::AbstractTask )
    readoff = update!(net)
    if teacher.last + teacher.period <= net.time
        set_time!(task, net.time)
        update_weights!(teacher.rule, net, task)
        teacher.last = teacher.last + teacher.period < net.time ? net.time : teacher.last + teacher.period
    end
    return readoff
end

