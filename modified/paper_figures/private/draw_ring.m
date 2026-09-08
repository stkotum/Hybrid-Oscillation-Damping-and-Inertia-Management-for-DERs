function draw_ring(ax, tg, cg, env_in, env_out, col, alpha)
% DRAW_RING  Fill the symmetric ring between cg +/- env_in and cg +/- env_out, i.e.
% only the band OUTSIDE the inner (controlled) envelope, so it never sits behind it.
% Arguments:
%   ax       (axes)            target axes
%   tg       (n x 1)           envelope time grid ([] -> no-op)
%   cg       (n x 1 | scalar)  band centre on tg (the COI curve)
%   env_in   (n x 1)           inner half-width (the controlled envelope)
%   env_out  (n x 1)           outer half-width (the uncontrolled envelope)
%   col      (1 x 3)           fill RGB (band_col)
%   alpha    (double)          face opacity
%
% This is what makes the narrowing legible: the controlled panel of Fig. 5 carries its
% own pale band as a core and the uncontrolled envelope as a ring around it.
if isempty(tg), return; end
if isscalar(cg), cg = cg*ones(size(tg)); end
eo = max(env_out, env_in);                       % outer never dips inside the inner edge
hu = fill(ax, [tg; flipud(tg)], [cg+env_in; flipud(cg+eo)], col, ...   % upper ring
          'EdgeColor','none', 'FaceAlpha',alpha, 'HandleVisibility','off');
hl = fill(ax, [tg; flipud(tg)], [cg-eo; flipud(cg-env_in)], col, ...   % lower ring
          'EdgeColor','none', 'FaceAlpha',alpha, 'HandleVisibility','off');
uistack(hu, 'bottom'); uistack(hl, 'bottom');
end
