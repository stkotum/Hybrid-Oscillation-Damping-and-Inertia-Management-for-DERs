function fig = perdev_figure(P)
% PERDEV_FIGURE  The shared body of Fig. 5(a) and Fig. 5(b): per-node frequency
% deviation f - f_0 with the COI overlaid, uncontrolled panel on the left and
% controlled panel on the right. The two figures differ only in where the data comes
% from and in how far the time axis runs, so they share this one layout.
% Arguments:
%   P  (struct)  the panel data and the few numbers that differ between 5(a) and 5(b):
%       .off, .on   structs with .t (n_t x 1), .F (n_t x n_node deviation from f_0)
%                   and .coi (n_t x 1)
%       .inertia    (n_node x 1)  ranks the f_i colours, darkest = most inertia
%       .gain       (double)      K of the controlled panel, for the nadir symbol
%       .xlim       (1x2)         time axis of both panels [s]
%       .ylim       (1x2)         shared frequency axis [Hz]
%       .env_x      (1x2)         window the swing envelopes are built over [s]
%       .nadir_x    (1x2)         window the COI nadir is taken over [s]
% Returns the figure handle; the caller exports it.
%
% The K = 0 / K = N*I labels are deliberately NOT drawn inside the panels. The paper
% sets them once as column headers above the two-row composite of 5(a) and 5(b) and
% marks the rows "(a) linear" / "(b) nonlin.", so a per-panel label would duplicate
% them. The column-header offsets in the paper are the panel centres, 0.455 + 1.32/2
% and the same plus the 1.53 in axis pitch, so they move with the geometry below.
%
% PAPER GEOMETRY. The plot boxes are placed by hand (place_axes_in) rather than left
% to subplot: 0.95 in tall instead of the ~1.2 in the automatic layout leaves, which is
% part of what keeps the paper inside its page limit. The legend is sized in inches for
% the same reason - see add_perdev_legend.
PANEL   = [1.32 0.95];          % plot box, inches
PANEL_X = [0.455 1.985];        % left edge of each panel, inches (1.53 in pitch)
PANEL_Y = 0.31;                 % shared bottom edge, inches

s   = paper_style('column','single','aspect',2.5);   % full column width, compact height
fig = paper_figure(s);

n_node = size(P.off.F, 2);
cw_off = ranked_line_ramp(P.inertia, n_node, 'red');     % uncontrolled panel: red ramp
cw_on  = ranked_line_ramp(P.inertia, n_node, 'green');   % controlled panel: same ramp, green
nad_off = window_min(P.off, P.nadir_x);
nad_on  = window_min(P.on,  P.nadir_x);

ax1 = perdev_panel(P.off, cw_off, nad_off, 1, s, P.xlim, [PANEL_X(1) PANEL_Y PANEL]);
ylabel(ax1,'$f - f_0$ in Hz','Interpreter','latex');
ax2 = perdev_panel(P.on,  cw_on,  nad_on,  2, s, P.xlim, [PANEL_X(2) PANEL_Y PANEL]);

% ===================================================== swing envelopes
% Peak-connected max_i |f_i - f_COI| around each panel's own COI trace. The CONTROLLED
% panel carries both: its own as a pale core and the uncontrolled one as a ring around
% it, which is what makes the narrowing legible. Each fill is sent to the back as it is
% drawn, so the ring ends up furthest back.
[tg, env_off] = coi_envelope(P.off.t, P.off.F - P.off.coi, P.env_x);
[~,  env_on ] = coi_envelope(P.on.t,  P.on.F  - P.on.coi,  P.env_x);
cg_off = interp1(P.off.t, P.off.coi, tg, 'linear','extrap');
cg_on  = interp1(P.on.t,  P.on.coi,  tg, 'linear','extrap');
draw_band(ax1, tg, cg_off, env_off, band_col('off'));
draw_band(ax2, tg, cg_on,  env_on,  band_col('on'),  0.90);
draw_ring(ax2, tg, cg_on,  env_on, env_off, band_col('off'), 0.90);

linkaxes([ax1 ax2],'y');
ylim(ax1, P.ylim);                  % fixed common y-range, shared through linkaxes

% The legend is placed in data coordinates, so it is drawn LAST, once linkaxes has
% settled the limits. Its nadir symbols carry the gain as a superscript, N_COI^0
% against N_COI^K, matching how the paper writes the pair. The swatch shows the smooth
% ramp; the curves themselves are the same ramp reordered by inertia.
add_perdev_legend(ax1, line_ramp(n_node,'red'),   s, PANEL, '$N_{\mathrm{COI}}^{0}$');
add_perdev_legend(ax2, line_ramp(n_node,'green'), s, PANEL, ...
                  ['$N_{\mathrm{COI}}^{' num2str(P.gain) '}$']);
end


% =========================================================================
function ax = perdev_panel(side, cw, nadir, col, s, xl, rect_in)
% PERDEV_PANEL  One of the two panels: the per-node f_i in their ramp, the COI on top
% in black, and a dotted line at this panel's COI nadir.
% Arguments:
%   side     (struct)  .t, .F, .coi for this panel
%   cw       (n x 3)   per-node colour ramp, inertia-ranked
%   nadir    (double)  COI nadir of this panel [Hz]
%   col      (double)  subplot column, 1 (uncontrolled) or 2 (controlled)
%   s        (struct)  paper_style struct
%   xl       (1x2)     time axis limits [s]
%   rect_in  (1x4)     plot box [left bottom width height], inches
ax = subplot(1,2,col); paper_axes(ax, s);
place_axes_in(ax, rect_in, s);
set(ax, 'ColorOrder', cw, 'ColorOrderIndex', 1);
plot(ax, side.t, side.F,   '-', 'LineWidth', s.lw_data);
plot(ax, side.t, side.coi, '-', 'Color',[0 0 0], 'LineWidth', s.lw_dataemph);
yline(ax, nadir, ':', 'Color',[0 0 0], 'LineWidth', s.lw_axis, 'HandleVisibility','off');
xlabel(ax,'Time since step in s','Interpreter','latex');
xlim(ax, xl);
end


function v = window_min(side, win)
% WINDOW_MIN  Minimum of a panel's COI trace over a time window (its nadir).
m = side.t >= win(1) & side.t <= win(2);
v = min(side.coi(m));
end
