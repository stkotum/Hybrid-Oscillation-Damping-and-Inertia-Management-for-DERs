function W = vik_wing()
% VIK_WING  The blue wing of Crameri's vik colormap, dark blue -> light blue.
%
% Rows 28:95 of the 256-entry vik table (colormaps/vik.txt): the blue side only, so
% there is no white centre and no warm/orange half. Every colour ramp in the paper is
% cut from this one range, which is what makes them read as a family:
%   sweep_colormap  reverses it (light at 0 % activation, dark at 100 %)
%   line_ramp       hue-rotates it to red (K = 0) or green (K != 0)
% Returns a 68 x 3 RGB matrix. Read once and cached for the session.
persistent W_CACHED
if isempty(W_CACHED)
    here = fileparts(mfilename('fullpath'));
    V = readmatrix(fullfile(here,'colormaps','vik.txt'));   % 256x3 vik (blue->white->red)
    W_CACHED = V(28:95, :);                                 % dark blue -> light blue
end
W = W_CACHED;
end
