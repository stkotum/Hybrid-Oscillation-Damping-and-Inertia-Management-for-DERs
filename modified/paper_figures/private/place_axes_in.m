function place_axes_in(ax, rect_in, s)
% PLACE_AXES_IN  Put an axes' plot box at an exact rectangle, measured in INCHES from
% the bottom-left corner of the paper canvas.
% Arguments:
%   ax       (axes handle)  target axes
%   rect_in  (1x4)          [left bottom width height] of the plot box [inches]
%   s        (struct)       paper_style struct (figure size)
%
% matlab2tikz bakes the plot box straight into the .tikz as width / height / at, so
% these four numbers ARE the figure's paper geometry. Setting them explicitly, instead
% of accepting whatever subplot's automatic layout leaves after fitting the labels, is
% what keeps a re-export at the size the paper's page budget was built around: the
% automatic layout depends on font metrics and therefore on the MATLAB release, and it
% leaves more slack around the panels than the page budget can afford.
set(ax, 'Units','normalized', ...
        'Position', [rect_in(1)/s.width_in,  rect_in(2)/s.height_in, ...
                     rect_in(3)/s.width_in,  rect_in(4)/s.height_in]);
end
