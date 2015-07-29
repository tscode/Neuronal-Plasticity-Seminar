# files
include("random.jl")
include("sprandn.jl")
include("misc.jl")
include("recorder.jl")
# types
export Recorder
# functions
export rand, shuffle, choice,
       unif, normal, randbool,
       randseed,
       sprandn, startswith, record,
       clear_records
export REC
