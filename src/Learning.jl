# symbols needed from main
import EvoNet: AbstractNetwork, LRNetwork, Network, dt
import EvoNet: update!, get_num_output, get_num_readout
using EvoNet.Utils
# files
include("learning/task.jl")
include("learning/force_rule.jl")
include("learning/reward_rule.jl")
include("learning/evaluator.jl")
include("learning/teacher.jl")
# types
export AbstractTask, FunctionTask,
       AbstractRule, ForceRule,
       AbstractTeacher, Teacher,
       AbstractEvaluator, Evaluator
# functions
export evaluate, reset, learn!
