function vec=normalizeLogVecNoUnderflow(vec)
% function vec=normalizeLogVecNoUnderflow(vec)
%
% returns the vector  exp(vec) after normalizing it.
% The normalization is done in a way that avoid
% common underflow and overflow problems.
%
% Guy Lebanon, August 2003.

vec = exp(vec-max(vec));
vec = vec / sum(vec);