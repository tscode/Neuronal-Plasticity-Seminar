using EvoNet.Utils
# files
include("param/parameter.jl")
include("param/parametric_object.jl")
include("param/meta_parametric_object.jl")
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
