function draw_eig_sector(ax, re_lo, im_hi, s)
% DRAW_EIG_SECTOR  Draw the design region of sector_spec on an eigenvalue panel: the
% two zeta-cone rays and the Re = -beta line, as thin dashed grey guides.
% Arguments:
%   ax      (axes handle)  target axes
%   re_lo   (double)       left end of the cone rays [rad/s]
%   im_hi   (double)       half-height of the Re = -beta line [rad/s]
%   s       (struct)       paper_style struct (line width)
%
% The rays are drawn out to Re = 0 and left to the axes to clip; paper_export's
% decimation clamps whatever leaves the box, so they never overflow TeX's max
% dimension. The Im = 0 centreline is drawn by draw_eig_grid, not here.
q  = sector_spec();
xc = linspace(re_lo, 0, 50);
plot(ax, xc, -xc*q.sinZ/q.cosZ, '--', 'Color',[.7 .7 .75], 'LineWidth',s.lw_axis, 'HandleVisibility','off');
plot(ax, xc,  xc*q.sinZ/q.cosZ, '--', 'Color',[.7 .7 .75], 'LineWidth',s.lw_axis, 'HandleVisibility','off');
plot(ax, [-q.beta -q.beta], [-im_hi im_hi], '--', 'Color',[.7 .7 .75], 'LineWidth',s.lw_axis, 'HandleVisibility','off');
end
