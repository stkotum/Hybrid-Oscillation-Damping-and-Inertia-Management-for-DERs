function feng9_diag_units()
% FENG9_DIAG_UNITS  Diagnose the nonlinear injection: (1) what 'Pref' resolves to and
% its units, (2) where the Pref constant connects, (3) what w_c represents
% (pu/Hz/rad-s).
% Arguments: (none)
feng9_nonlinear_setup;                                  % base-ws params (Pref, pset, ...)
mdl = 'simulation_model'; load_system(mdl);
probe(mdl,'INVERTER 1','Area 1','GFL', 1);
probe(mdl,'INVERTER 2','Area 1','GFM', 2);
close_system(mdl,0);
end

function probe(mdl, invname, area, kind, k)
% PROBE  Print Pref resolution, destination, mask P-setpoint vars and the w_c
% source/scaling for one converter.
% Arguments:
%   mdl      (char)    model name
%   invname  (char)    INVERTER subsystem name (e.g. 'INVERTER 1')
%   area     (char)    parent area name (e.g. 'Area 1')
%   kind     (char)    converter kind label ('GFL'/'GFM'), for the banner
%   k        (double)  converter index 1..9 (selects the w_c{k} Goto tag)
fprintf('\n==================== %s (%s) ====================\n', invname, kind);
inv = [mdl '/' area '/' invname];
% converter subsystem (child of INVERTER named GFL*/GFM*)
conv = find_system(inv,'SearchDepth',1,'BlockType','SubSystem');
conv = conv(~strcmp(conv,inv)); conv = conv{1};
fprintf('converter: %s\n', oneline(conv));

% ============================ Pref constant: value + resolved numeric + dest
cs = find_system(conv,'LookUnderMasks','on','FollowLinks','off','BlockType','Constant');
for i=1:numel(cs)
    v = oneline(get_param(cs{i},'Value'));
    if strcmpi(strtrim(v),'Pref')
        fprintf('Pref Constant: %s   Value="%s"\n', oneline(cs{i}), v);
        try, rv = slResolve('Pref', cs{i}); fprintf('   Pref resolves to: %s\n', mat2str(rv)); catch e, fprintf('   resolve fail: %s\n', e.message); end
        % destination
        ph = get_param(cs{i},'PortHandles'); lh = get_param(ph.Outport(1),'Line');
        db = get_param(lh,'DstBlockHandle'); dp = get_param(lh,'DstPortHandle');
        if all(db>0)
            for j=1:numel(db)
                fprintf('   -> [%s] %s  (inport %d)\n', get_param(db(j),'BlockType'), ...
                        oneline(getfullname(db(j))), get_param(dp(j),'PortNumber'));
            end
        end
    end
end

% ================================= mask workspace values relevant to P setpoint
try
    mv = get_param(conv,'MaskWSVariables');
    for i=1:numel(mv)
        if ~isempty(regexpi(mv(i).Name,'pref|pset|p_set|^P$','once'))
            fprintf('mask var %-10s = %s\n', mv(i).Name, mat2str(mv(i).Value));
        end
    end
catch, end

% ===================== w_c source: trace and look for scaling (1/2/pi/fb => pu)
g = find_system(mdl,'BlockType','Goto','GotoTag',sprintf('w_c%d',k));
fprintf('w_c%d Goto: %s\n', k, oneline(g{1}));
ph = get_param(g{1},'PortHandles'); lh = get_param(ph.Inport(1),'Line');
src = get_param(lh,'SrcBlockHandle');
fprintf('  fed by [%s] %s\n', get_param(src,'BlockType'), oneline(getfullname(src)));
% look for gains named like a freq scaling inside the converter
gs = find_system(conv,'LookUnderMasks','on','FollowLinks','off','BlockType','Gain');
for i=1:numel(gs)
    kk = oneline(get_param(gs{i},'Gain'));
    if ~isempty(regexpi(kk,'pi|fb|wb|2\*pi','once'))
        fprintf('  gain near freq: %s  K=%s\n', oneline(get_param(gs{i},'Name')), kk);
    end
end
end

function s = oneline(s)
% ONELINE  Collapse newlines in a string to spaces (single-line printing).
% Arguments:
%   s  (char)  input string (may contain newlines)
s = strrep(strrep(s,newline,' '),char(10),' '); end
