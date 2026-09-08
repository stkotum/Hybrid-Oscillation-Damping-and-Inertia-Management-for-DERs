function stems = make_paper_figures(varargin)
% MAKE_PAPER_FIGURES  Render the five MATLAB figures of the paper into figures/.
% Arguments (name-value):
%   'gain'  (double, default 20)   communicated-damping gain K = gain*I of the
%                                  twelve-bus example (Fig. 4, 5a, 5b) [MW.s/rad]
%   'only'  (char | cellstr)       render a subset: any of fig4, fig5a, fig5b,
%                                  fig6, fig7. Default: all five.
%
%   make_paper_figures                              % all five, paper settings
%   make_paper_figures('only', 'fig7')              % just the COI envelope sweep
%   make_paper_figures('only', {'fig6','fig7'})     % just the large-system sweep
%   make_paper_figures('gain', 20)                  % explicit K for the small example
%
% Figures, all written as vector PDF + 600-dpi PNG + PGF/TikZ (the .tikz is what the
% paper \inputs):
%   fig4_linear_eig                    Fig. 4   twelve-bus spectrum, K = 0 vs K = 20 I
%   fig5a_linear_perdev_off_vs_on      Fig. 5a  per-node deviation, linearised
%   fig5b_nonlinear_perdev_off_vs_on   Fig. 5b  per-node deviation, nonlinear
%   fig6_eig_zoom_3cases               Fig. 6   spectrum over the activation sweep
%   fig7_coi_envelope_3cases           Fig. 7   COI envelope over the sweep
% Returns a cell array of the written path stems.
%
% Each builder is also callable on its own (fig7_coi_envelope_3cases, ...); this is
% just the loop over all five. What each one needs on disk is in README.md - Fig. 5b
% needs the two saved Simscape runs (skipped with a warning when they are absent),
% and Fig. 6/7 run their per-share linear simulations on first call and cache them
% under _cache/.
ALL = {'fig4','fig5a','fig5b','fig6','fig7'};
p = inputParser;
p.addParameter('gain', 20, @(x) isnumeric(x) && isscalar(x));
p.addParameter('only', ALL, @(x) ischar(x) || iscellstr(x) || isstring(x));
p.parse(varargin{:}); o = p.Results;

want = cellstr(o.only);
bad  = setdiff(want, ALL);
if ~isempty(bad)
    error('make_paper_figures:unknown', 'unknown figure(s): %s. Pick from %s.', ...
          strjoin(bad, ', '), strjoin(ALL, ', '));
end

cfg = paper_config('gain', o.gain);
if ~exist(cfg.outdir,'dir'), mkdir(cfg.outdir); end

builders = struct( ...
    'fig4',  @fig4_linear_eig, ...
    'fig5a', @fig5a_linear_perdev, ...
    'fig5b', @fig5b_nonlinear_perdev, ...
    'fig6',  @fig6_eig_zoom_3cases, ...
    'fig7',  @fig7_coi_envelope_3cases);

fprintf('=== paper figures (K = %d) -> %s ===\n', cfg.gain, cfg.outdir);
stems = cell(1, numel(want));
for i = 1:numel(want)
    fprintf('\n-- %s --\n', want{i});
    try
        stems{i} = builders.(want{i})(cfg);
    catch ME
        if strcmp(ME.identifier, 'nonlinear_data:missing')
            % Fig. 5(b) needs the two saved Simscape runs, which are not shipped with
            % the repository. Skip it and go on, so the other figures are still drawn.
            warning('make_paper_figures:skipped', '%s skipped: %s', want{i}, ME.message);
            stems{i} = '';
            continue
        end
        rethrow(ME);
    end
    fprintf('   %s.{pdf,png,tikz}\n', stems{i});
end
stems = stems(~cellfun(@isempty, stems));
fprintf('\nDONE.  %d figure(s) in %s\n', numel(stems), cfg.outdir);
end
