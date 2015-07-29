#
# OPTIMIZE - UTILS
#

import EvoNet.Utils: record

# the default method to record a rating
record(rec, id, rating::AbstractRating) = record(rec, id, get_value(rating))

# the default method to record parametric objects
function record(rec, id, object::AbstractParametricObject)
  params = export_params(object)
  values = [get_value(i) for i in params]
  record(rec, id, vcat(values...))
end

