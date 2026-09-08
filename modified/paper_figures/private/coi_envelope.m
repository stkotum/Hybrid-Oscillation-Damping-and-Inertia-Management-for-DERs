function [tg, env] = coi_envelope(t, dev, xr)
% COI_ENVELOPE  Smooth decreasing envelope of the per-node swing |f_i - f_COI|.
% Arguments:
%   t    (n_t x 1)       step-relative time vector (matches dev rows)
%   dev  (n_t x n_node)  per-node deviation from the COI, f_i - f_COI
%   xr   (1 x 2)         [tmin tmax]; the envelope is built over the window [0, tmax]
%
% Returns the envelope half-width env on a uniform grid tg in [0, tmax]. E(t) =
% max_i |f_i - f_COI| is the largest swing across nodes at each instant (abs, so a
% node dipping below the COI counts as a positive excursion). Up to the FIRST swing
% peak the envelope follows E exactly, so it rises with the f_i straight off the step.
% From the first peak on it is a smooth (pchip) curve through the successive swing
% peaks (the local maxima of E), so it connects peak to peak without dipping into the
% troughs between them and without needing a threshold.
E = max(abs(dev), [], 2);                          % largest |deviation| across nodes
m = t >= 0 & t <= xr(2); tw = t(m); Ew = E(m);     % post-step window only
if numel(tw) < 3, tg = []; env = []; return; end
ws  = max(1, round(numel(tw)/400));                % light smoothing to suppress ripple
tg  = linspace(0, xr(2), 400).';
Eg  = max(interp1(tw, movmean(Ew, ws), tg, 'linear', 'extrap'), 0);  % precise envelope on grid
d   = diff(Eg);
pk  = find(d(1:end-1) > 0 & d(2:end) <= 0) + 1;    % local maxima (swing peaks)
env = Eg;                                           % no peaks -> just follow E
if ~isempty(pk)
    nodes = unique([pk; numel(tg)]);               % peaks + window end (anchors the tail)
    ip1 = pk(1);                                    % first peak: follow E exactly up to it,
    env(ip1:end) = interp1(tg(nodes), Eg(nodes), tg(ip1:end), 'pchip');  % then connect peak
end                                                 % to peak smoothly, skipping the troughs
env = max(env, 0);
end
