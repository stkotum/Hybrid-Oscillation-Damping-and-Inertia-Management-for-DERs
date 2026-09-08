function paper_export(fig, basepath, axis_options)
% PAPER_EXPORT  Save a paper-ready figure as vector PDF, 600-dpi PNG, and PGF/TikZ.
% Arguments:
%   fig           (figure handle)  figure to export (closed on return)
%   basepath      (char)           output file path stem (no extension)
%   axis_options  (cellstr, optional, default {})  pgfplots options appended to EVERY
%                 axis of the .tikz. For the handful of things pgfplots can express and
%                 MATLAB cannot - matlab2tikz translates properties, so anything with
%                 no MATLAB counterpart has to arrive this way instead of as a hand
%                 edit that the next export would silently drop.
%
% Writes <basepath>.pdf (vector, LaTeX-importable), <basepath>.png (600-dpi raster
% preview), and <basepath>.tikz (PGFPlots/TikZ via matlab2tikz, \input-able in
% LaTeX with \usepackage{pgfplots}). The .tikz is what the paper actually \inputs;
% the PDF is the standalone preview. The figure is closed on return.
if nargin < 3 || isempty(axis_options), axis_options = {}; end
d = fileparts(basepath);
if ~isempty(d) && ~exist(d,'dir'), mkdir(d); end

% =============================================== vector PDF (canonical artifact)
% ContentType=vector keeps lines/text resolution-independent for LaTeX import.
exportgraphics(fig, [basepath '.pdf'], 'ContentType','vector', 'BackgroundColor','w');

% =============================================== raster PNG (600-dpi preview)
exportgraphics(fig, [basepath '.png'], 'Resolution',600, 'BackgroundColor','w');

% =============================================== PGF/TikZ for LaTeX (matlab2tikz)
% Done AFTER the pdf/png so those keep full data. The dense nonlinear lines (~600k
% samples) are decimated first (prune to each axis' x-limits, then cap points per
% line) so the .tikz stays small and matlab2tikz does not choke. matlab2tikz lives
% in modified/external/ (gitignored); if absent the .tikz is skipped, not an error.
here    = fileparts(mfilename('fullpath'));   % modified/paper_figures/private
mroot   = fileparts(fileparts(here));         % modified
m2tsrc  = fullfile(mroot,'external','matlab2tikz','src');
if exist('matlab2tikz','file')~=2 && isfolder(m2tsrc), addpath(m2tsrc); end
if exist('matlab2tikz','file')==2
    try
        decimate_lines(fig, 2000);     % keep .tikz small; preserves the visible curve
        matlab2tikz([basepath '.tikz'], 'figurehandle', fig, ...
            'showInfo', false, 'checkForUpdates', false, ...   % no network call in batch runs
            'standalone', false, 'floatFormat', '%.6g', ...
            'extraAxisOptions', axis_options);
        % hoist fonts, the legend box, and the size into LaTeX macros (see
        % figures/paperfig_preamble.tex) so the figure is adjustable at compile time.
        tikz_make_adjustable([basepath '.tikz']);
    catch ME
        warning('paper_export:pgf', 'PGF/.tikz export skipped for %s (%s)', basepath, ME.message);
    end
else
    warning('paper_export:pgf', 'matlab2tikz not found under modified/external/ - .tikz skipped');
end

close(fig);
end

% =========================================================================
function decimate_lines(fig, maxpts)
% DECIMATE_LINES  Shrink every line for PGF/TikZ export: drop points outside the
% axis x-range (also thins dense nonlinear traces), clamp survivors to a box a few axis
% ranges out, and cap the point count. The clamp keeps the on-axis curve exact while
% bounding off-axis coordinates (e.g. eig damping-ratio cone lines that shoot far past
% ylim, or ~1e11 droop poles) that would otherwise overflow TeX's max dimension.
% Arguments:
%   fig     (figure handle)  figure whose line objects are decimated in place
%   maxpts  (double)         max points kept per line (after x-range pruning)
ls = findall(fig, 'Type', 'line');
for i = 1:numel(ls)
    L  = ls(i);
    xd = get(L, 'XData'); yd = get(L, 'YData'); n = numel(xd);
    keep = true(1, n);
    ax = ancestor(L, 'axes');
    if ~isempty(ax) && isvalid(ax)
        xl = get(ax, 'XLim');                    % prune off-window x (far poles; thins nonlinear)
        keep = (xd >= xl(1) & xd <= xl(2));
    end
    xk = xd(keep); yk = yd(keep); nk = numel(xk);
    if ~isempty(ax) && isvalid(ax)               % clamp survivors to ~10 axis ranges out:
        yl = get(ax, 'YLim');                    % off-axis points stay off-screen but
        xr = xl(2)-xl(1); yr = yl(2)-yl(1);      % finite, so cone lines / huge poles can't
        xk = min(max(xk, xl(1)-10*xr), xl(2)+10*xr);   % overflow TeX's max dimension while
        yk = min(max(yk, yl(1)-10*yr), yl(2)+10*yr);   % the visible curve is left exact
    end
    if nk > maxpts                               % uniform thinning to the cap
        idx = round(linspace(1, nk, maxpts)); xk = xk(idx); yk = yk(idx);
    end
    set(L, 'XData', xk, 'YData', yk);
end
end
