# symbols needed from main
import EvoNet: AbstractNetwork, LRNetwork, Network, dt
import EvoNet: update!, get_num_output, get_num_readout
using EvoNet.Utils
# files
include("task.jl")
include("force_rule.jl")
include("reward_rule.jl")
include("evaluator.jl")
include("teacher.jl")
# types
export AbstractTask, FunctionTask,
       AbstractRule, ForceRule,
       AbstractTeacher, Teacher,
       AbstractEvaluator, Evaluator
# functions
export evaluate, reset, learn!, get_expected
