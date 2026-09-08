function stem = fig4_linear_eig(cfg)
% FIG4_LINEAR_EIG  Paper Fig. 4: the twelve-bus small-signal spectrum, K = 0 against
% K = N*I, as one single-column figure of two abutting panels.
% Arguments:
%   cfg  (struct, optional, default paper_config())  paths and gain
% Returns the output path stem (paper_export appends .pdf/.png/.tikz).
%
%   fig4_linear_eig
%   fig4_linear_eig(paper_config('gain', 20))
%
% LEFT panel  Re in [-150, -6], the zoomed-out spectrum.
% RIGHT panel Re in [-6, 1], the electromechanical region, and it carries the legend.
% The split at Re = -6 sits inside the spectral gap (-6.155 .. -5.093), so the two
% panels tile the spectrum with no mode drawn twice. Both share one Im range, +/-40.
%
% The rigid omega = theta-dot mode at the origin is dropped: it is not part of the
% small-signal stability picture, and neither it nor the SG modes influence the virtual
% inertia choice or the controller.
%
% PAPER GEOMETRY. The two plot boxes are placed by hand (place_axes_in) rather than
% left to subplot, which pads them to about 0.985 in tall - too much whitespace for the
% column. These are the numbers the paper's layout was built around.
PANEL  = [1.171 0.788];         % plot box, inches
PANEL_X = [0.455 1.930];        % left edge of each panel, inches
PANEL_Y = 0.31;                 % shared bottom edge, inches
if nargin < 1 || isempty(cfg), cfg = paper_config(); end
L = linear_data(cfg);

s   = paper_style('column','single','aspect',2.5);   % two panels side by side, compact
fig = paper_figure(s);

e_off = L.off.ev(abs(L.off.ev) > 1e-4);
e_on  = L.on.ev (abs(L.on.ev)  > 1e-4);
im_lim = 40;                    % shared Im-axis half-height for BOTH panels

% ===== LEFT: zoomed out, ending exactly where the right panel picks up
ax1 = subplot(1,2,1); paper_axes(ax1, s); grid(ax1,'off');   % manual grid, see draw_eig_grid
place_axes_in(ax1, [PANEL_X(1) PANEL_Y PANEL], s);
draw_eig_grid(ax1, [-150 -6], [-im_lim im_lim], -140:10:-10, [-20 0 20], s);
draw_eig_sector(ax1, -150, im_lim, s);
plot_spectrum(ax1, e_off, e_on, s);
xlim(ax1,[-150 -6]); ylim(ax1,[-im_lim im_lim]);
xticks(ax1,[-150 -6]); yticks(ax1,[-40 0 40]);      % sparse labels; the centreline is labelled
xlabel(ax1,'$\mathrm{Re}(\lambda)$ in rad/s','Interpreter','latex');
ylabel(ax1,'$\mathrm{Im}(\lambda)$ in rad/s','Interpreter','latex');

% ===== RIGHT: electromechanical region + the single shared legend
ax2 = subplot(1,2,2); paper_axes(ax2, s); grid(ax2,'off');
place_axes_in(ax2, [PANEL_X(2) PANEL_Y PANEL], s);
draw_eig_grid(ax2, [-6 1], [-im_lim im_lim], [], [-20 0 20], s);   % no vertical lines here
draw_eig_sector(ax2, -6, im_lim, s);
h = plot_spectrum(ax2, e_off, e_on, s);
set(h(1), 'DisplayName', '$K = 0$');
set(h(2), 'DisplayName', sprintf('$K = %g\\,I$', cfg.gain));
xlim(ax2,[-6 1]); ylim(ax2,[-im_lim im_lim]);
xticks(ax2,[-5 0]); yticks(ax2,[-40 0 40]);
xlabel(ax2,'$\mathrm{Re}(\lambda)$ in rad/s','Interpreter','latex');
lg = legend(ax2, h, 'Location','northeast', 'Interpreter','latex', 'FontSize',s.fontsize);
set(lg, 'Color','w', 'EdgeColor','k', 'TextColor','k');
lg.ItemTokenSize = [9 8];      % short marker samples, so the box clears the sector cone

stem = fullfile(cfg.outdir, 'fig4_linear_eig');
paper_export(fig, stem);
end


% =========================================================================
function h = plot_spectrum(ax, e_off, e_on, s)
% PLOT_SPECTRUM  The two mode sets in the paper's convention: red crosses for the
% uncontrolled case, filled Pantone-301 dots for the controlled one.
% Returns the two line handles, in that order, for the legend.
h(1) = plot(ax, real(e_off), imag(e_off), 'x', 'Color',s.red, ...
            'MarkerSize',4.6, 'LineWidth',0.9, 'LineStyle','none');
h(2) = plot(ax, real(e_on),  imag(e_on),  'o', 'Color',s.p301, 'MarkerFaceColor',s.p301, ...
            'MarkerSize',2.8, 'LineWidth',0.4, 'LineStyle','none');
end
