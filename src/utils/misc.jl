
#
# MISC
#
# Miscellaneous stuff, and utility functions

# For the parameter matching of the Meta-Topology, ect...
function startswith{T<:String}(str::T, beg::T)
  return length(beg) > length(str) ? false : str[1:sizeof(beg)] == beg
end


