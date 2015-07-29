# files
include("utils/random.jl")
include("utils/sprandn.jl")
include("utils/misc.jl")
include("utils/recorder.jl")
# types
export Recorder
# functions
export rand, shuffle, choice,
       unif, normal, randbool,
       randseed,
       sprandn, startswith, record,
       clear_records
export REC
