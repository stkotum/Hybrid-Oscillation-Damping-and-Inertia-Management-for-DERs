function panel_title(ax, name, s)
% PANEL_TITLE  The case-name column header of the sweep figures (WECC / SC500 /
% Texas2000), bold and two points above the body size.
% Arguments:
%   ax    (axes handle)  target axes
%   name  (char)         case name; no "(a)" prefix and no K, the paper's caption
%                        carries both
%   s     (struct)       paper_style struct (font, fontsize)
%
% The gap to the axis is closed on the LaTeX side by \figtitleshift (see
% figures/paperfig_preamble.tex): matlab2tikz's default title gap looks too large once
% the figure is at paper size.
title(ax, name, 'Interpreter','latex', 'FontName',s.font, 'FontWeight','bold', ...
      'FontSize',s.fontsize+2, 'Color','k');
end
