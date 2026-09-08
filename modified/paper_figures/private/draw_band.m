function draw_band(ax, tg, cg, env, col, alpha)
% DRAW_BAND  Fill a symmetric translucent swing band (cg +/- env), behind the curves.
% Arguments:
%   ax     (axes)            target axes
%   tg     (n x 1)           envelope time grid from coi_envelope ([] -> no-op)
%   cg     (n x 1 | scalar)  band centre on tg (the COI curve)
%   env    (n x 1)           envelope half-width on tg
%   col    (1 x 3)           fill RGB (band_col)
%   alpha  (double, optional, default 0.90)  face opacity
if nargin < 6, alpha = 0.90; end
if isempty(tg), return; end
if isscalar(cg), cg = cg*ones(size(tg)); end
xb = [tg; flipud(tg)]; yb = [cg - env; flipud(cg + env)];
hf = fill(ax, xb, yb, col, 'EdgeColor','none', 'FaceAlpha',alpha, 'HandleVisibility','off');
uistack(hf, 'bottom');                           % send behind whatever is drawn so far
end
