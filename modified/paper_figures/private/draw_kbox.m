function draw_kbox(fig, rect_in, s)
% DRAW_KBOX  Framed K = 0 (red cross) / K != 0 (blue dot) marker key, drawn as a small
% axes at RECT_IN.
% Arguments:
%   fig      (figure handle)  target figure
%   rect_in  (1x4)            [left bottom width height] on the canvas, inches
%   s        (struct)         paper_style struct (colours, font, line widths)
%
% Drawn by hand rather than as a legend object, because a real legend stays anchored
% to its host axes and would float up beside a panel instead of sitting under the grid.
% The two entries are STACKED (K = 0 on top), markers in a shared left column and the
% labels in a column to their right, so the box comes out narrow and two rows tall.
ax = axes(fig); place_axes_in(ax, rect_in, s); hold(ax,'on');
plot(ax, 0.13, 0.78, 'x', 'Color',s.red, 'MarkerSize',4.4, 'LineWidth',0.9);
text(ax, 0.27, 0.78, '$K = 0$', 'Interpreter','latex','FontName',s.font, ...
     'FontSize',s.fontsize, 'VerticalAlignment','middle', 'Color','k');
plot(ax, 0.13, 0.24, 'o', 'Color',s.p301, 'MarkerFaceColor',s.p301, 'MarkerSize',2.8);
text(ax, 0.27, 0.24, '$K \neq 0$', 'Interpreter','latex','FontName',s.font, ...
     'FontSize',s.fontsize, 'VerticalAlignment','middle', 'Color','k');
xlim(ax,[0 1]); ylim(ax,[0 1]);
set(ax, 'XTick',[],'YTick',[],'Box','on','XColor','k','YColor','k', ...
        'LineWidth',s.lw_axis,'Color','w','Layer','top');
end
