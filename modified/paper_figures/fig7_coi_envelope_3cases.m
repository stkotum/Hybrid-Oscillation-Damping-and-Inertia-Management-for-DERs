function stem = fig7_coi_envelope_3cases(cfg)
% FIG7_COI_ENVELOPE_3CASES  Paper Fig. 7: the COI envelope over the activation sweep,
% three systems across and three quantities down, at full text width.
% Arguments:
%   cfg  (struct, optional, default paper_config())  paths and sweep cases
% Returns the output path stem (paper_export appends .pdf/.png/.tikz).
%
%   fig7_coi_envelope_3cases
%
% Columns are WECC, SC500 and Texas2000; rows are
%   top     Delta f_COI(t)                            with a zoom inset on the nadir
%   middle  max_i |f_i(t) - f_COI(t)|,  the envelope
%   bottom  that envelope minus its own 0 % baseline  (<= 0; lower = more reduction)
% Every curve is one activation share, coloured by share_style: the 0 % baseline red
% and emphasised, every other share in the sweep ramp.
%
% This figure is DOUBLE-COLUMN (7.16 in, \begin{figure*}): the 3x3 grid is unreadable
% in one IEEE column. It is sized at its FINAL paper size - the paper applies no
% \figscale - so what comes out here is what the float occupies.
%
% HEIGHT BUDGET. It was compacted from 3.14 in to about 2.2 in of paper height, which
% is what keeps the paper inside its page limit. This is the most fragile figure of the
% set; after any change, re-check the exported height before rebuilding the paper. What
% buys the height, all of it below:
%   1. a taller aspect (2.35 -> 3.20): the same width on a shorter canvas
%   2. only the bottom row keeps its x tick numbers. All three rows share one time
%      axis, so the row gap no longer has to hold three sets of them and only has to
%      clear the y tick numbers overhanging each panel edge
%   3. the y labels moved into the LaTeX caption; as two-line rotated labels they no
%      longer fit beside a panel this short
%   4. the colour bar lost its 'Share of units damped in %' label, also moved to the
%      caption, which closes the gap underneath it
if nargin < 1 || isempty(cfg), cfg = paper_config(); end
S = sweep_data(cfg);

s   = paper_style('column','double','aspect',3.20);
fig = paper_figure(s);
te    = S(1).results{1}.t_event;     % step instant, identical across cases
to_hz = 1/(2*pi);                    % rad/s -> Hz  (omega = 2 pi f)
xL    = [-0.025 2];
% Placement of the three row labels, in pgfplots terms because MATLAB has no property
% that maps to it: horizontal (pgfplots rotates y labels by default, so rotate=-90
% undoes it) and right-anchored at -0.145 of the axis width, which puts them just
% clear of the y tick numbers and right-aligns the three rows against each other.
% Applied to every axis of the figure; the ones without a y label ignore it.
ROW_YLABEL_STYLE = ['ylabel style={rotate=-90, ' ...
                    'at={(axis description cs:-0.145,0.5)}, anchor=east}'];

% Zoom windows for the top row, one per case. The x window is the post-step nadir,
% where the spread between shares is largest; the y windows are per case because the
% three systems swing an order of magnitude apart. The first two were tuned in rad/s
% and are converted here; Texas2000 is given directly in Hz.
zoom = struct( ...
    'x',  {[0 0.5],               [0 0.5],              [0 0.5]}, ...
    'y',  {[-0.275 -0.26]*to_hz,  [-0.13 -0.11]*to_hz,  [-0.023 -0.0215]}, ...
    'yt', {[],                    [],                   [-0.023 -0.0215]});

% ================================================== the three channels, per case
% Computed once and reused: the middle and the bottom row are the same envelope, and
% for Texas2000 that max over ~10 000 samples is the expensive part of the figure.
coi = cell(1,3); env = cell(1,3); red = cell(1,3);
for p = 1:3
    R      = S(p).results;
    coi{p} = cellfun(@(r) r.wcoi*to_hz,       R, 'UniformOutput', false);
    env{p} = cellfun(@(r) peak_envelope(r)*to_hz, R, 'UniformOutput', false);
    red{p} = envelope_reduction(R, env{p});
end

axT = gobjects(1,3);   % top row    Delta f_COI
axM = gobjects(1,3);   % middle row peak rel-COI envelope
axB = gobjects(1,3);   % bottom row envelope reduction against the 0 % baseline

for p = 1:3            % ============================= top row: COI deviation
    axT(p) = sweep_panel(p, S(p), coi{p}, te, xL, s);
    set(axT(p), 'XTickLabel', {});             % shares the bottom row's time axis
    panel_title(axT(p), S(p).name, s);
end
for p = 1:3            % ============================= middle row: peak envelope
    axM(p) = sweep_panel(3+p, S(p), env{p}, te, xL, s);
    set(axM(p), 'XTickLabel', {});
end
for p = 1:3            % ============================= bottom row: its reduction
    axB(p) = sweep_panel(6+p, S(p), red{p}, te, xL, s);
    xlabel(axB(p),'Time since step in s','Interpreter','latex');   % one per column
end

% One y label per row, on the leftmost column only. They are set HORIZONTAL rather
% than rotated: at this panel height a horizontal label reads better, and it costs
% less height than a rotated one costs width. The exact placement is a pgfplots
% option (ROW_YLABEL_STYLE below), because MATLAB has no property for it.
row_ylabel(axT(1), '$\Delta\fcoi(t)$');
row_ylabel(axM(1), '$\max_i|f_i(t)-\fcoi(t)|$');
row_ylabel(axB(1), '$\Delta\max_i|f_i(t)-\fcoi(t)|$');

% One shared y-axis for the three bottom panels: their reductions are close in scale.
% The top is pinned just above zero, since the curves are <= 0 bar small overshoots.
ymin = 0;
for p = 1:3
    for k = 1:numel(red{p})
        win  = (S(p).results{k}.tt - te) >= xL(1) & (S(p).results{k}.tt - te) <= xL(2);
        ymin = min(ymin, min(red{p}{k}(win)));       % deepest dip in view
    end
end
for p = 1:3, ylim(axB(p), [1.05*ymin, 0.01*to_hz]); end

% ============================ place the 3x3 grid on the canvas (see HEIGHT BUDGET)
% Every number here is in inches on the 7.16 x 2.24 in canvas, because they ARE the
% paper geometry: subplot's automatic layout leaves 0.388 in rows with 0.168 in gaps,
% which is 0.4 in of whitespace this figure cannot afford.
%   rows      0.460 in tall on a 0.565 in pitch, i.e. 0.105 in gaps. The gap only has
%             to clear the y tick numbers overhanging each panel edge, since only the
%             bottom row carries x tick numbers.
%   columns   1.910 in pitch. subplot leaves 0.482 in between columns where the tick
%             numbers need about 0.28 in; the row labels are wide and would otherwise
%             push the picture past \textwidth, so the width comes out of those gaps.
%   top       the top row ends at 2.150 in, leaving 0.088 in for the column headers,
%             which \figtitleshift pulls down into it.
PANEL = [1.528 0.460];                 % plot box of every panel, inches
COL_X = [0.931 2.841 4.752];           % left edge of each column, inches
ROW_Y = [1.690 1.125 0.560];           % bottom edge of the top / middle / bottom row
for p = 1:3
    place_axes_in(axT(p), [COL_X(p) ROW_Y(1) PANEL], s);
    place_axes_in(axM(p), [COL_X(p) ROW_Y(2) PANEL], s);
    place_axes_in(axB(p), [COL_X(p) ROW_Y(3) PANEL], s);
end

% At most two y-tick numbers per panel and plain decimals (never a 10^-2 common
% factor), so the stacked 3x3 grid stays legible at this height.
for ax = [axT axM axB]
    yt = get(ax,'YTick');
    if numel(yt) > 2, yt = yt([1 end]); end
    set(ax,'YTick', yt, 'YTickLabel', arrayfun(@(v)sprintf('%g',v), yt, 'UniformOutput',false));
end

% Insets go on AFTER the placement, so they track the final panel geometry.
for p = 1:3
    add_coi_zoom_inset(axT(p), S(p), coi{p}, te, zoom(p), ...
                       [COL_X(p) ROW_Y(1) PANEL], s);
end

% Shared colour bar below the grid, spanning the leftmost to the rightmost column, so
% it stays aligned with the panels whatever the column pitch is.
CBAR_H = 0.097; CBAR_Y = 0.130;        % inches: bar height and its bottom edge
cbar_w = (COL_X(3) + PANEL(1)) - COL_X(1);
draw_share_colorbar(fig, [COL_X(1) CBAR_Y cbar_w CBAR_H], S(1).shares, s);

stem = fullfile(cfg.outdir, 'fig7_coi_envelope_3cases');
paper_export(fig, stem, {ROW_YLABEL_STYLE});
end


% =========================================================================
function ax = sweep_panel(idx, sim, curves, te, xL, s)
% SWEEP_PANEL  One panel of the 3x3 grid: every activation share of one case, drawn in
% its share colour.
% Arguments:
%   idx     (double)  subplot index in the 3x3 grid
%   sim     (struct)  one sweep_data entry (.results, .shares)
%   curves  (cell)    one y-vector per share, on that share's own time grid
%   te      (double)  step instant subtracted from R.tt [s]
%   xL      (1x2)     shared time axis [s]
%   s       (struct)  paper_style struct
%
% The y labels are in the paper caption, see the HEIGHT BUDGET note above.
ax = subplot(3,3,idx); paper_axes(ax, s);
for k = 1:numel(sim.shares)
    [c, lw] = share_style(sim.shares(k), s);
    plot(ax, sim.results{k}.tt - te, curves{k}, '-', 'Color', c, 'LineWidth', lw);
end
xlim(ax, xL);
end


function env = peak_envelope(R)
% PEAK_ENVELOPE  max_i |omega_i(t) - omega_COI(t)|: the worst node's deviation from
% the COI at each instant [rad/s].
env = max(abs(R.omega - R.wcoi), [], 2);
end


function red = envelope_reduction(results, env)
% ENVELOPE_REDUCTION  Each share's peak envelope minus the 0 % baseline envelope,
% interpolated onto that share's own time grid.
% Arguments:
%   results  (cell)  per-share result structs; results{1} is the 0 % baseline
%   env      (cell)  the matching peak envelopes [Hz]
% Returns a cell of curves that are <= 0, the first one flat at zero.
base_t = results{1}.tt; base_env = env{1};
red = cellfun(@(R, e) e - interp1(base_t, base_env, R.tt, 'linear','extrap'), ...
              results(:), env(:), 'UniformOutput', false);
end


function row_ylabel(ax, txt)
% ROW_YLABEL  One horizontal row label on the leftmost panel of a row. The horizontal
% orientation is set here so the MATLAB PDF matches the .tikz; the .tikz gets its own
% rotate=-90 from ROW_YLABEL_STYLE, since matlab2tikz does not translate label rotation.
ylabel(ax, txt, 'Interpreter','latex', 'Rotation',0, ...
       'HorizontalAlignment','right', 'VerticalAlignment','middle');
end


function add_coi_zoom_inset(parent_ax, sim, coi, te, zoom, panel_in, s)
% ADD_COI_ZOOM_INSET  Mark the zoom window on a top-row panel and re-plot the same COI
% curves into a small inset axes restricted to it.
% Arguments:
%   parent_ax  (axes handle)  the panel the inset belongs to
%   sim        (struct)       one sweep_data entry
%   coi        (cell)         the panel's COI curves, one per share [Hz]
%   te         (double)       step instant subtracted from R.tt [s]
%   zoom       (struct)       .x, .y limits and .yt explicit y ticks ([] = auto)
%   panel_in   (1x4)          the parent panel's plot box, inches
%   s          (struct)       paper_style struct
%
% GEOMETRY, all of it load-bearing at this figure height:
%   - the inset sits 0.085 in below the panel's top edge and NOT LESS. Its upper y tick
%     label is centred on that edge; at 0.045 in the label crossed the panel border.
%   - the x tick numbers carry yshift=1.5pt, applied on the LaTeX side by
%     tikz_make_adjustable. Unshifted, the 0 and the 0.4 sat on the settled COI trace of
%     the panel behind and their digits were cut. 1.5 pt is near the ceiling: about
%     3.1 pt separate the digit tops from the inset's bottom border.
INSET     = [0.642 0.170];    % inset plot box [width height], inches
INSET_PAD = [0.061 0.085];    % gap to the panel's right edge / top edge, inches
rectangle(parent_ax, 'Position', [zoom.x(1), zoom.y(1), diff(zoom.x), diff(zoom.y)], ...
          'EdgeColor', [0 0 0], 'LineStyle','--', 'LineWidth', 0.7);

ax = axes('Parent', get(parent_ax,'Parent'));
place_axes_in(ax, [panel_in(1) + panel_in(3) - INSET_PAD(1) - INSET(1), ...
                   panel_in(2) + panel_in(4) - INSET_PAD(2) - INSET(2), INSET], s);
hold(ax,'on');
set(ax, 'Color','w', 'Box','on', ...
        'FontName', s.font, 'FontSize', max(5, s.fontsize-2), ...
        'XColor','k', 'YColor','k', 'LineWidth', s.lw_axis, 'TickLength',[0.025 0.025]);

for k = 1:numel(sim.shares)
    [c, lw] = share_style(sim.shares(k), s);
    plot(ax, sim.results{k}.tt - te, coi{k}, '-', 'Color', c, 'LineWidth', lw);
end
xlim(ax, zoom.x); ylim(ax, zoom.y);
xticks(ax, [0 0.4]);                        % only the window ends, the panel is tiny
if ~isempty(zoom.yt)                        % explicit ticks and plain decimals, where
    set(ax, 'YTick', zoom.yt, ...           % the automatic two-tick reduction
            'YTickLabel', arrayfun(@(v)sprintf('%g',v), zoom.yt, 'UniformOutput',false));
else                                        % misbehaves (Texas2000)
    yt = get(ax,'YTick');
    if numel(yt) > 2, set(ax, 'YTick', yt([1 end])); end
end
end
