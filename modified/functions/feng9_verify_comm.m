function feng9_verify_comm()
% FENG9_VERIFY_COMM  Structural check of simulation_model_damping_comm.slx:
% confirm the communication network and the 9 Pref+Pdamp injections are fully
% wired (no compile / no simulation - that nonlinear run is expensive).
% Arguments: (none)
new = 'simulation_model_damping_comm';
load_system(new);
ok = true;

% comm network blocks
need = {'wcMux','wcBias','CommGain','PdampDemux'};
for i=1:numel(need)
    b = find_system(new,'SearchDepth',1,'Name',need{i});
    if isempty(b), fprintf('  MISSING %s\n', need{i}); ok=false;
    else, fprintf('  ok  %s\n', need{i}); end
end

% all input ports of CommGain / Bias / Mux / Demux connected
for nm = {'wcMux','wcBias','CommGain','PdampDemux'}
    b = find_system(new,'SearchDepth',1,'Name',nm{1}); b=b{1};
    ok = ok & ports_connected(b, nm{1});
end

% 9 Pdamp_c goto driven, 9 From w_c driven
for k=1:9
    g = find_system(new,'BlockType','Goto','GotoTag',sprintf('Pdamp_c%d',k));
    if isempty(g), fprintf('  MISSING Goto Pdamp_c%d\n',k); ok=false; continue; end
    if ~inport_has_line(g{1},1), fprintf('  UNWIRED Goto Pdamp_c%d\n',k); ok=false; end
end

% each converter: a Pdamp_Sum with both inputs + output connected
sums = find_system(new,'LookUnderMasks','on','FollowLinks','off','regexp','on','Name','Pdamp_Sum');
fprintf('  found %d Pdamp_Sum blocks (expect 9)\n', numel(sums));
if numel(sums) ~= 9, ok=false; end
for i=1:numel(sums)
    s = sums{i};
    good = inport_has_line(s,1) & inport_has_line(s,2) & outport_has_line(s,1);
    if ~good, fprintf('  UNWIRED %s\n', oneline(s)); ok=false; end
end

% the 9 Pdamp_From inside converters
froms = find_system(new,'LookUnderMasks','on','FollowLinks','off','regexp','on','Name','Pdamp_From');
fprintf('  found %d Pdamp_From blocks (expect 9)\n', numel(froms));
if numel(froms) ~= 9, ok=false; end

fprintf('\n  RESULT: %s\n', string(ok));
close_system(new,0);
end

function ok = ports_connected(b, label)
% PORTS_CONNECTED  True if every inport and outport of a block has a line;
% prints any unwired port.
% Arguments:
%   b      (char/handle)  block path or handle to check
%   label  (char)         name used in the UNWIRED diagnostic message
ph = get_param(b,'PortHandles'); ok=true;
for i=1:numel(ph.Inport)
    if ~port_has_line(ph.Inport(i)), fprintf('  UNWIRED %s inport %d\n',label,i); ok=false; end
end
for i=1:numel(ph.Outport)
    if ~port_has_line(ph.Outport(i)), fprintf('  UNWIRED %s outport %d\n',label,i); ok=false; end
end
end
function tf = inport_has_line(b,k)
% INPORT_HAS_LINE  True if inport k of block b has a connected line.
% Arguments:
%   b  (char/handle)  block path or handle
%   k  (double)       inport index
ph=get_param(b,'PortHandles'); tf=port_has_line(ph.Inport(k));  end
function tf = outport_has_line(b,k)
% OUTPORT_HAS_LINE  True if outport k of block b has a connected line.
% Arguments:
%   b  (char/handle)  block path or handle
%   k  (double)       outport index
ph=get_param(b,'PortHandles'); tf=port_has_line(ph.Outport(k)); end
function tf = port_has_line(p)
% PORT_HAS_LINE  True if a port handle has a line attached.
% Arguments:
%   p  (handle)  port handle
tf = get_param(p,'Line') > 0; end
function s = oneline(s)
% ONELINE  Collapse newlines in a string to spaces (single-line printing).
% Arguments:
%   s  (char)  input string (may contain newlines)
s = strrep(strrep(s,newline,' '),char(10),' '); end
