function stem = fig6_eig_zoom_3cases(cfg)
% FIG6_EIG_ZOOM_3CASES  Paper Fig. 6: the small-signal A^ss spectrum over the
% activation sweep, one square panel per large system (WECC, SC500, Texas2000).
% Arguments:
%   cfg  (struct, optional, default paper_config())  paths and sweep cases
% Returns the output path stem (paper_export appends .pdf/.png/.tikz).
%
%   fig6_eig_zoom_3cases
%
% Every panel shows all eleven activation shares at once: the 0 % baseline as red
% crosses and each activated share as dots in its sweep colour. Re is clipped to
% [-15, 1]; the Im range is taken per case from the modes that survive that clip.
% The design region of sector_spec is drawn as dashed guides.
%
% Underneath the panels sit the share colour bar and the K = 0 / K != 0 marker key,
% drawn by hand as small axes (draw_share_colorbar, draw_kbox) so they can be placed
% exactly. They are centred as one group under the panel grid, derived from the actual
% panel positions, so a layout change keeps them centred without hand-tuned offsets.
% matlab2tikz trims the empty space below them, so the figure still renders compact.
%
% PAPER GEOMETRY, in inches on the 3.50 x 1.49 in canvas: three square panels raised
% to free a strip along the bottom for the key group, which is centred under them.
PANEL  = [0.747 0.745];              % plot box of every panel, inches
COL_X  = [0.455 1.438 2.421];        % left edge of each panel, inches
ROW_Y  = 0.596;                      % shared bottom edge, inches
CBAR   = [1.400 0.067]; CBAR_Y = 0.156;    % share colour bar, inches
KBOX   = [0.619 0.200]; KBOX_Y = 0.025;    % K = 0 / K != 0 marker key, inches
KBOX_GAP = 0.210;                    % gap between the bar and the key, inches
if nargin < 1 || isempty(cfg), cfg = paper_config(); end
S = sweep_data(cfg);

s   = paper_style('column','single','aspect',2.35);
fig = paper_figure(s);
re_lo = -15;

axE = gobjects(1,3);
for p = 1:3
    axE(p) = subplot(1,3,p); ax = axE(p); paper_axes(ax, s);
    place_axes_in(ax, [COL_X(p) ROW_Y PANEL], s);
    im_hi = im_extent(S(p).results, re_lo);

    draw_eig_sector(ax, re_lo, im_hi, s);
    plot(ax, [re_lo 1], [0 0], '-', 'Color',[.88 .88 .88], 'LineWidth', s.lw_axis);
    for k = 1:numel(S(p).shares)
        ev = S(p).results{k}.ev;
        ev = ev(abs(ev) > 1e-4);          % drop the rigid omega = theta-dot mode at 0
        c  = share_style(S(p).shares(k), s);
        if S(p).shares(k) == 0            % uncontrolled baseline: red crosses
            plot(ax, real(ev), imag(ev), 'x', 'Color', c, ...
                 'MarkerSize', 4.4, 'LineWidth', 0.9, 'LineStyle','none');
        else                              % activated share: filled dot in its sweep colour
            plot(ax, real(ev), imag(ev), 'o', 'Color', c, 'MarkerFaceColor', c, ...
                 'MarkerSize', 2.5);
        end
    end
    xlim(ax,[re_lo 1]); ylim(ax,[-im_hi im_hi]);
    xlabel(ax,'$\mathrm{Re}(\lambda)$ in rad/s','Interpreter','latex');
    if p == 1, ylabel(ax,'$\mathrm{Im}(\lambda)$ in rad/s','Interpreter','latex'); end
    panel_title(ax, S(p).name, s);
end

% ================= the [colour bar | marker key] group, centred under the panel grid
% Centred on the grid rather than on the canvas, and derived from the panel geometry
% above, so a layout change keeps it centred without hand-tuned offsets. The key sits
% low enough to clear the Re(lambda) axis labels. matlab2tikz trims the empty space
% below it, so the figure still renders compact at paper size.
grid_ctr = (COL_X(1) + COL_X(3) + PANEL(1)) / 2;
group_L  = grid_ctr - (CBAR(1) + KBOX_GAP + KBOX(1))/2;
draw_share_colorbar(fig, [group_L CBAR_Y CBAR], S(1).shares, s, ...
                    'Share of units damped in \%');
draw_kbox(fig, [group_L+CBAR(1)+KBOX_GAP KBOX_Y KBOX], s);

stem = fullfile(cfg.outdir, 'fig6_eig_zoom_3cases');
paper_export(fig, stem);
end


% =========================================================================
function im_hi = im_extent(results, re_lo)
% IM_EXTENT  Half-height of the Im axis for one case: 15 % of headroom above the
% highest |Im| among the non-rigid modes that survive the Re clip, floored at 8 rad/s
% so a case with only slow modes still gets a readable panel.
allev = cell2mat(cellfun(@(R) R.ev(:), results(:), 'UniformOutput', false));
evp   = allev(abs(allev) > 1e-4);
if isempty(evp), evp = allev; end
im_hi = max(8, 1.15*max(abs(imag(evp(real(evp) >= re_lo)))));
end
