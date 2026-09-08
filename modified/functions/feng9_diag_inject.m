function feng9_diag_inject()
% FENG9_DIAG_INJECT  For the modified model, confirm each of the 9 Pdamp_Sum
% injections sits on the real active-power-setpoint path: print Sum input1 (the
% Pref constant + value), input2 (the Pdamp From), and the Sum output
% destination (block + inport).
% Arguments: (none)
mdl = 'simulation_model_damping_comm'; load_system(mdl);
sums = find_system(mdl,'LookUnderMasks','on','FollowLinks','off','regexp','on','Name','Pdamp_Sum');
fprintf('found %d Pdamp_Sum\n', numel(sums));
for i=1:numel(sums)
    s = sums{i};
    ph = get_param(s,'PortHandles');
    fprintf('\n%s\n', oneline(s));
    for p = 1:numel(ph.Inport)
        lh = get_param(ph.Inport(p),'Line'); sb = get_param(lh,'SrcBlockHandle');
        bt = get_param(sb,'BlockType'); nm = oneline(getfullname(sb)); v='';
        if strcmp(bt,'Constant'), v = [' value=' oneline(get_param(sb,'Value'))]; end
        if strcmp(bt,'From'),     v = [' tag='   oneline(get_param(sb,'GotoTag'))]; end
        fprintf('  in%d <- [%s] %s%s\n', p, bt, nm, v);
    end
    lo = get_param(ph.Outport(1),'Line'); db = get_param(lo,'DstBlockHandle'); dp = get_param(lo,'DstPortHandle');
    for j=1:numel(db)
        fprintf('  out -> [%s] %s (inport %d)\n', get_param(db(j),'BlockType'), oneline(getfullname(db(j))), get_param(dp(j),'PortNumber'));
    end
end
close_system(mdl,0);
end
function s = oneline(s)
% ONELINE  Collapse newlines in a string to spaces (single-line printing).
% Arguments:
%   s  (char)  input string (may contain newlines)
s = strrep(strrep(s,newline,' '),char(10),' '); end
