function run_large_systems()
% RUN_LARGE_SYSTEMS  Damping-activation sweep over the three allocated large
% MATPOWER cases (WECC, SC500, Texas2000) at paper-canonical per-case gains, and the
% two paper figures drawn from it.
% Arguments: (none)
%
%   run_large_systems
%
% Per-case K (paper-canonical, set in paper_figures/private/paper_config):
%   WECC       K = 15   (deep inside sector: max Re = -7.31, no overdamping)
%   SC500      K =  9   (deep inside sector: max Re = -9.30)
%   Texas2000  K =  4   (sector-tight: max Re = -3.006)
%
% Output, in modified/paper_figures/figures/:
%   fig6_eig_zoom_3cases       Fig. 6  small-signal A^ss eigenvalues over the sweep
%   fig7_coi_envelope_3cases   Fig. 7  COI deviation, peak rel-COI envelope, and that
%                                      envelope's reduction against the 0 % baseline
%
% Caching: per-case paper_figures/_cache/<case>/result_share_<NNN>_K<K>.mat. Re-running
% reuses every cached share that matches the K - fast unless K changes or the cache
% directory is cleared by hand.

here  = fileparts(mfilename('fullpath'));     % modified/runnable
mroot = fileparts(here);                      % modified
addpath(fullfile(mroot,'paper_figures'));

fprintf('=== Large-system sweep: WECC, SouthCarolina500, Texas2000 ===\n');
fprintf('Paper-canonical K = [15, 9, 4] (WECC, SC500, Texas2000)\n\n');

make_paper_figures('only', {'fig6','fig7'});
end
