function C = ranked_line_ramp(inertia, n, which)
% RANKED_LINE_RAMP  LINE_RAMP colours assigned by inertia rank: the node/channel with
% the LARGEST (virtual) inertia gets the darkest colour, the smallest the lightest.
% Arguments:
%   inertia  (n-vector)  per-node inertia (M_ii / virtual inertia), same order as the
%                        plotted f_i columns. Empty or length ~= n falls back to the
%                        plain index-order ramp.
%   n        (double)    number of colours
%   which    (char)      'red' | 'green', passed through to line_ramp
%
% The ranking is shared by the K = 0 and K != 0 panels of Fig. 5, so a node keeps its
% position in the ordering across the two hues.
base = line_ramp(n, which);                      % base(1,:) darkest -> base(n,:) lightest
C = base;
if ~isempty(inertia) && numel(inertia) == n
    [~, ord] = sort(inertia(:), 'descend');      % ord(1) = highest-inertia node
    C(ord, :) = base;                            % highest inertia -> darkest
end
end
