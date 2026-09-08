function C = line_ramp(n, which)
% LINE_RAMP  n per-node f_i line colours: the sweep's blue ramp recoloured.
% Arguments:
%   n      (double)  number of colours
%   which  (char)    'red' (uncontrolled, K = 0 panel) | 'green' (controlled panel)
%
% The vik blue wing (vik_wing, the same range sweep_colormap uses) is hue-rotated,
% keeping its light->dark saturation/value profile, so the f_i lines carry exactly the
% style of the blue sweep ramp in a different hue. Red and green are the SAME ramp
% under two rotations, so a node keeps its place in the light-to-dark ordering across
% the K = 0 and K != 0 panels of Fig. 5.
%
% The rotation is all there is to it: pushing the red ramp brighter or more saturated
% to clear the uncontrolled envelope was tried and rejected. The separation is made at
% the band instead (band_col), which is light enough that the ramp's light end still
% reads against it.
% Returns an n x 3 RGB matrix, darkest first, to set as an axes ColorOrder.
persistent RAMPS
if isempty(RAMPS)
    RAMPS = containers.Map('KeyType','char','ValueType','any');
end
if ~isKey(RAMPS, which)
    hsv = rgb2hsv(vik_wing());          % dark -> light blue
    hsv(:,1) = ramp_hue(which);         % rotate the hue, keep saturation & value
    RAMPS(which) = hsv2rgb(hsv);        % dark -> light, the blue ramp's style
end
G   = RAMPS(which);
idx = round(linspace(1, size(G,1), n));
C   = G(idx, :);
end


function h = ramp_hue(which)
% RAMP_HUE  Hue (0..1) the blue wing is rotated onto for a given panel.
switch validatestring(which, {'red','green'})
    case 'red',   h = 0.00;    % uncontrolled, K = 0
    case 'green', h = 0.30;    % controlled,   K != 0
end
end
