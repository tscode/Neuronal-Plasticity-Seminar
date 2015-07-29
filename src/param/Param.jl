using EvoNet.Utils
# files
include("parameter.jl")
include("parametric_object.jl")
include("meta_parametric_object.jl")
# types
export AbstractParameter, RelativeParameter,
       AbsoluteParameter, NormedSumParameter, 
       AbstractParametricObject, ParameterContainer, 
       MetaCombinationParam
# functions
export export_params, import_params!, 
       get_name, random_param, get_value, 
       combine
# macros
export @MakeMeta, @MakeMetaGen
