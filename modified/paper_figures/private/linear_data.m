function L = linear_data(cfg)
% LINEAR_DATA  The linearised twelve-bus pair behind Fig. 4 and Fig. 5(a):
% D^com = 0 against D^com = C K C' with K = cfg.gain * I.
% Arguments:
%   cfg  (struct)  paper_config settings
%
% Rebuilds the two case files (build_linear_cases, in modified/linear/) and integrates
% both with simulate_linear, returning
%   L.off, L.on  the two simulate_linear result structs (fields tt, t_event, f0, fabs,
%                fcoi, frel, ev, m, ... - see simulate_linear)
%
% Cheap enough to just run, but memoized per gain so Fig. 4 and Fig. 5(a) in one
% session share a single build+integrate.
persistent CACHE
key = sprintf('K%g', cfg.gain);
if ~isempty(CACHE) && strcmp(CACHE.key, key)
    L = CACHE.data; return
end

fprintf('  linear pair: build_linear_cases(%d) + simulate_linear OFF/ON\n', cfg.gain);
build_linear_cases(cfg.gain);
L = struct('off', simulate_linear(cfg.case_off), ...
           'on',  simulate_linear(cfg.case_on));

CACHE = struct('key', key, 'data', L);
end
