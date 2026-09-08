function draw_share_colorbar(fig, rect_in, shares, s, label)
% DRAW_SHARE_COLORBAR  Horizontal share-of-units-damped colour bar (the sweep_colormap
% ramp, light blue at 0 % to dark blue at 100 %) drawn into FIG at RECT_IN.
% Arguments:
%   fig      (figure handle)  target figure
%   rect_in  (1x4)            [left bottom width height] on the canvas, inches
%   shares   (vector)         swept activation shares [percent]; every second one is
%                             labelled, to keep the bar uncluttered
%   s        (struct)         paper_style struct (font, sizes, line widths)
%   label    (char, optional, default '')  axis label under the bar. Empty for Fig. 7,
%            where it moved into the LaTeX caption: it was what stood between the bar
%            and the bottom of the float, and that figure has no height to spare.
%
% Drawn by hand as a small axes rather than as a colorbar object so it can sit exactly
% where the layout wants it, and so both sweep figures get the identical bar.
if nargin < 5, label = ''; end
%
% The bar carries a RED BLOCK at its zero end, because the 0 % case is drawn in red
% rather than in the ramp (share_style). Without it the bar would promise a light-blue
% baseline curve that no panel contains. The block is sized in INCHES, not in share
% units: the two bars in the paper are ~1.4 in and ~5.3 in wide, so a fixed share
% width would print as a sliver on one and a square on the other.
%
% The 'Share of units damped in %' label lives in the paper caption; it is what stood
% between the bar and the bottom of the float. See the height budget in
% fig7_coi_envelope_3cases.
ax = axes(fig); place_axes_in(ax, rect_in, s);
n = 256; img = zeros(1,n,3);
for k = 1:n, img(1,k,:) = sweep_colormap((k-1)/(n-1)*100); end
image(ax, [0 100], [0 1], img);
hold(ax,'on');
mark_w = 100 * min(0.25, 0.10 / rect_in(3));       % about 0.10 in of red
patch(ax, [0 mark_w mark_w 0], [0 0 1 1], s.red, 'EdgeColor','none');
tk = shares(1:2:end);                              % 0, 20, ..., 100 (avoid clutter)
set(ax, 'YTick',[], 'Box','on', 'FontName',s.font, 'FontSize',max(5,s.fontsize-1), ...
        'XTick',tk, 'XTickLabel',arrayfun(@(p)sprintf('%d',p),tk,'UniformOutput',false), ...
        'XColor','k','YColor','k','LineWidth',s.lw_axis, 'TickLength',[0.02 0.02]);
if ~isempty(label)
    xlabel(ax, label, 'Interpreter','latex', 'FontSize', max(5,s.fontsize-1));
end
xlim(ax,[0 100]); ylim(ax,[0 1]);
end
