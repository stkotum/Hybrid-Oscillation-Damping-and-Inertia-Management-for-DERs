function draw_eig_grid(ax, xlims, ylims, xv, yv, s)
% DRAW_EIG_GRID  Light reference grid for an eigenvalue panel, drawn as plain lines
% BEHIND the data instead of the per-tick auto grid, so the lines sit where we want
% them while the tick labels stay sparse.
% Arguments:
%   ax     (axes handle)  target axes (call before plotting the data)
%   xlims  (1x2)          horizontal extent of the horizontal lines [rad/s]
%   ylims  (1x2)          vertical extent of the vertical lines [rad/s]
%   xv     (vector)       Re values to draw vertical lines at ([] for none)
%   yv     (vector)       Im values to draw horizontal lines at, e.g. the Im = 0
%                         centreline ([] for none)
%   s      (struct)       paper_style struct (line width)
gc = [.85 .85 .85];                  % matches the faint paper grid (s.gray at alpha 0.3 on white)
for x = xv(:).'
    plot(ax, [x x], ylims, '-', 'Color', gc, 'LineWidth', s.lw_axis, 'HandleVisibility','off');
end
for y = yv(:).'
    plot(ax, xlims, [y y], '-', 'Color', gc, 'LineWidth', s.lw_axis, 'HandleVisibility','off');
end
end
