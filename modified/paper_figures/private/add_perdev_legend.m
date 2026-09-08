function add_perdev_legend(ax, cw, s, panel_in, nadir_sym)
% ADD_PERDEV_LEGEND  Draw the Fig. 5 mini-legend (f_COI / f_i / nadir) in data coords.
% Arguments:
%   ax         (axes handle)  the legend is drawn into this axes
%   cw         (n x 3)        per-node RGB ramp of THIS panel (red for K = 0, green for
%                             K != 0); its row count sets the number of swatch segments
%   s          (struct)       paper_style struct (font, fontsize, line widths)
%   panel_in   (1x2)          the panel's plot box [width height], inches
%   nadir_sym  (char)         LaTeX symbol for the nadir row, e.g.
%                             '$N_{\mathrm{COI}}^{0}$'
%
% Three rows in a framed box in the top-right corner:
%   f_COI   black solid line
%   f_i     an n-segment stripe of the panel's own ramp - the colour palette in
%           miniature, so the swatch literally is the key to the f_i curves
%   nadir   black dotted line
%
% Everything is placed in the axes' DATA coordinates, so this must be called LAST,
% after linkaxes and the final xlim/ylim are settled - otherwise the box drifts when
% the paired axis rescales.
%
% The BOX ITSELF is sized in inches and only then converted to data units, because the
% label font is fixed in points: sizing it as a fraction of the data range instead
% shrank the three rows into each other as soon as the panel was shortened for the page
% budget, while the labels stayed put. Sized this way it survives any panel resize.
BOX_IN = [0.514 0.372];    % legend frame [width height], inches: the three rows at
                           % 8 pt, plus the swatch column and the margins around them
hold(ax,'on');
n_bus = size(cw, 1);
xl = xlim(ax); yl = ylim(ax);
W = xl(2) - xl(1); H = yl(2) - yl(1);

box_w = BOX_IN(1)/panel_in(1) * W;   % inches -> data units, per axis
box_h = BOX_IN(2)/panel_in(2) * H;
margin = 0.020;

box_left   = xl(2) - margin*W - box_w;
box_top    = yl(2) - margin*H;
box_bottom = box_top - box_h;

% White background with a thin black border.
rectangle(ax, 'Position', [box_left, box_bottom, box_w, box_h], ...
          'FaceColor','w', 'EdgeColor','k', 'LineWidth', s.lw_axis);

% Internal layout: a swatch column on the left, a label column on the right.
inner_pad = 0.05 * box_w;
sw_left   = box_left + inner_pad;
sw_w      = 0.32 * box_w;
sw_right  = sw_left + sw_w;
text_x    = sw_right + 0.6*inner_pad;

% Three evenly-spaced row centres (top, middle, bottom).
row_y = box_top - box_h * [0.20; 0.50; 0.80];

% ===================== Row 1: f_COI
plot(ax, [sw_left sw_right], [row_y(1) row_y(1)], '-', ...
     'Color',[0 0 0], 'LineWidth', s.lw_dataemph, 'HandleVisibility','off');
legend_text(ax, text_x, row_y(1), '$f_{\mathrm{COI}}$', s);

% ===================== Row 2: the per-node ramp as a segmented stripe
seg_w = sw_w / n_bus;
for k = 1:n_bus
    xa = sw_left + (k-1)*seg_w;
    plot(ax, [xa xa+seg_w], [row_y(2) row_y(2)], '-', ...
         'Color', cw(k,:), 'LineWidth', 1.6*s.lw_data, 'HandleVisibility','off');
end
legend_text(ax, text_x, row_y(2), '$f_i$', s);

% ===================== Row 3: the COI nadir line
plot(ax, [sw_left sw_right], [row_y(3) row_y(3)], ':', ...
     'Color',[0 0 0], 'LineWidth', s.lw_axis, 'HandleVisibility','off');
legend_text(ax, text_x, row_y(3), nadir_sym, s);
end


function legend_text(ax, x, y, txt, s)
% LEGEND_TEXT  One left-aligned, vertically centred legend label in paper typography.
text(ax, x, y, txt, ...
     'Interpreter','latex', 'FontName',s.font, 'FontSize',s.fontsize, ...
     'VerticalAlignment','middle', 'Color','k');
end
