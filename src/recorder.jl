

export @record

type Recorder
    __dict__::Dict{Union(Symbol, Expr, Integer), Any}
end
Recorder() = Recorder(Dict{Union(Symbol, Expr, Integer), Array{Any}}())


function record(rec::Recorder, id::Union(Symbol, Integer), content::Real)
    if haskey(rec.__dict__, id)
        push!(rec.__dict__[id], Float64(content))
    else
        rec.__dict__[id] = Float64[content]
    end
end

function record(rec::Recorder, id::Union(Symbol, Integer), content::Vector{Float64})
    if haskey(rec.__dict__, id)
        rec.__dict__[id] = [rec.__dict__[id]; content']
    else
        rec.__dict__[id] = Float64[content]
    end
end

macro testr(args...)
    for arg in args print(arg) end
end

macro rec(args...)
    loop = args[end]
    if typeof(loop) == Symbol || !(loop.head in [:while, :for])
        error("'rec' macro needs loop as last parameter")
    end
    if length(args) == 1 return 42 end
    names = args[1:end-1] # each 'name' looks like :x or like :(x = y)
    # define stuff to do in the loop
    i = 0
    in_loop  = Expr[]
    for name in names
        if typeof(name) == Symbol
            i += 1
            push!( in_loop, :(EvoNet.record(EvoNet.REC, $i, $name))) #push!( in_loop, :(record(REC, 1, time)))
        elseif name.head == :(=) # If we get a name assignment -> symbol and variable are not the same, e.g. :(time = net.time)
            sym = Expr(:quote, :($(name.args[1]))) # sym = :(:time)
            push!( in_loop, :(EvoNet.record(EvoNet.REC, $sym, $(name.args[2]))) ) #push!( in_loop, :(record(REC, :time, net.time))
        else # Then we have something like name = :(a.b) or name = :(a.b[i])
            i += 1
            push!( in_loop, :(EvoNet.record(EvoNet.REC, $i, $name))) #push!( in_loop, :(record(REC, 2, a.b)))
        end
    end
    for expr in in_loop
        push!(loop.args[2].args, expr) # append the in_loop expressions to the loop
    end

    return esc(Expr(:block, loop))
end

function clear_records() 
    REC = EvoNet.Recorder()
end

# global recorder variable as convenience
REC = Recorder()

#=import Core.getfield # should work?! but currently doesn't!=#
#=getfield(rec::Recorder, id::Symbol) = rec.__dict__[id]=#
import Base.getindex
getindex(rec::Recorder, sym) = rec.__dict__[sym]
import Base.show
function show(io::IO, rec::Recorder)
    if isempty(rec.__dict__)
        print(io, "Empty Recorder")
    else
        print(io, "Recorder with records for:", keys(rec.__dict__)...)
    end
end
