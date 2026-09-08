function S = sweep_data(cfg)
% SWEEP_DATA  The damping-activation sweep behind Fig. 6 and Fig. 7: for each of the
% three allocated large systems, one linear run per activation share.
% Arguments:
%   cfg  (struct)  paper_config settings (uses .sweep, .shares, .cachedir)
%
% Returns a 1 x 3 struct array, one entry per case, with
%   .name      (char)    display name (WECC / SC500 / Texas2000)
%   .gain      (double)  that case's K
%   .shares    (vector)  activation shares [percent]
%   .n_active  (vector)  units actually damped at each share
%   .results   (cell)    one simulate_linear struct per share
%
% Units are activated in ascending order of native damping d, so the least-damped
% units are recruited first; a nonzero share always activates at least two (a single
% unit has nothing to exchange with). The communicated layer is the zero-sum
% D^com = K C C' built on the active set.
%
% CACHING. Each share lands in <cfg.cachedir>/<case id>/result_share_<NNN>_K<K>.mat
% and is reused on the next call, so restyling a figure never re-runs a simulation.
% The tag carries K, so changing a gain simply misses the cache instead of silently
% reusing the wrong run. Nothing else invalidates it: if the scenario .mat changes,
% delete the case's cache directory by hand. The three directories total ~650 MB and
% are gitignored. Memoized in-session as well, so Fig. 6 and Fig. 7 share one sweep.
persistent CACHE
key = sprintf('%s|%s', mat2str(cfg.shares), strjoin( ...
      arrayfun(@(c) sprintf('%s@%g', c.id, c.gain), cfg.sweep, 'UniformOutput', false), ','));
if ~isempty(CACHE) && strcmp(CACHE.key, key)
    S = CACHE.data; return
end

S = cfg.sweep;
for i = 1:numel(S)
    fprintf('  -- %s @ K=%g --\n', S(i).name, S(i).gain);
    [S(i).results, S(i).n_active] = run_case_sweep(S(i), cfg);
    S(i).shares = cfg.shares;
end

CACHE = struct('key', key, 'data', S);
end


% =========================================================================
function [results, n_active] = run_case_sweep(c, cfg)
% RUN_CASE_SWEEP  Sweep one case over cfg.shares, hitting the disk cache where it can.
% Arguments:
%   c    (struct)  one cfg.sweep entry (.id, .scenario, .gain)
%   cfg  (struct)  paper_config settings
if ~exist(c.scenario,'file')
    error('sweep_data:missing', '%s not found (needed for the %s sweep).', c.scenario, c.name);
end
D = load(c.scenario);
n = numel(D.m);
[~, order] = sort(D.d(:), 'ascend');       % least-damped units are activated first

cachedir = fullfile(cfg.cachedir, c.id);
if ~exist(cachedir,'dir'), mkdir(cachedir); end
K_tag = sprintf('K%s', strrep(sprintf('%.4g', c.gain), '.', 'p'));   % K15, K0p115, ...

shares   = cfg.shares;
n_active = zeros(size(shares));
results  = cell(numel(shares),1);
for k = 1:numel(shares)
    nc = round(shares(k)/100 * n);
    if shares(k) > 0, nc = max(2, nc); end   % a lone unit has nothing to exchange with
    n_active(k) = nc;

    cache_path = fullfile(cachedir, sprintf('result_share_%03d_%s.mat', shares(k), K_tag));
    if exist(cache_path,'file')
        R = load(cache_path);
        results{k} = R.R;
        fprintf('    share %3d%% (%2d active)  cached\n', shares(k), nc);
        continue
    end

    Dk = D;
    Dk.Dcom = comm_layer(order(1:nc), n, c.gain);
    if isstruct(Dk.meta)
        Dk.meta.gain            = c.gain;
        Dk.meta.sweep_share_pct = shares(k);
        Dk.meta.sweep_n_active  = nc;
    end
    casepath = fullfile(cachedir, sprintf('case_share_%03d_%s.mat', shares(k), K_tag));
    save(casepath, '-struct', 'Dk');
    R = simulate_linear(casepath);
    save(cache_path, 'R');
    results{k} = R;
    fprintf('    share %3d%% (%2d active)\n', shares(k), nc);
end
end


function Dcom = comm_layer(active, n, gain)
% COMM_LAYER  Zero-sum communicated damping D^com = K C C' on the ACTIVE unit set.
% Arguments:
%   active  (vector)  indices of the activated units ([] -> no communication)
%   n       (double)  number of units in the case
%   gain    (double)  K [MW.s/rad]
%
% C is the centring projector on the active set, so each active unit exchanges only
% the difference to the active-set average and the layer injects zero net power.
Dcom = zeros(n);
if isempty(active), return; end
nc = numel(active);
C = zeros(n);
C(active, active) = eye(nc) - ones(nc)/nc;
Dcom = gain * (C * C');
end
