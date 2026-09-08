function build_feng9_nonlinear_comm(out_name)
% BUILD_FENG9_NONLINEAR_COMM  Build the inter-DER damping-communication nonlinear model by
% transforming the upstream simulation_model.slx into the hand-tuned layout of
% simulation_model_damping_comm.slx. Two clearly separated stages:
% Arguments:
%   out_name  (char, optional, default 'simulation_model_damping_comm')  output model name; the built .slx is saved as <out_name>.slx
%
%   PART 1 (ADD)   add the damping-communication network + the per-converter
%                  Pref+Pdamp injection, at the exact hand-tuned positions and
%                  in TUM blue (the "adjustment" blocks), and wire them.
%   PART 2 (MOVE)  reposition the existing upstream blocks that were moved by
%                  hand for nicer visibility (exact target positions baked in).
%
% The damping network:
%   * reads the 9 inverter frequencies w_c1..w_c9 (NOT the 2 synchronous
%     machines), forms Dw = w_c - 1 [pu], multiplies by the communicated-damping
%     gain matrix D_comm (a WORKSPACE VARIABLE -> the model is gain-agnostic,
%     one .slx for all K) to get the zero-sum injection dP = D_comm*Dw [W],
%     1' D_comm = 0, and broadcasts Pdamp_c1..Pdamp_c9;
%   * inside each converter the active-power reference becomes Pref + Pdamp_c{k}
%     (a Sum block on the Pref wire).
% A single Memory block on the broadcast bus inserts a one-solver-step unit
% delay - its ONLY purpose is to break the omega -> Pref algebraic loop.
%
%   build_feng9_nonlinear_comm                 % builds models/simulation_model_damping_comm.slx
%   build_feng9_nonlinear_comm('foo')          % builds foo.slx instead (for testing /
%                                        % verification without touching the canonical model)
%
% D_comm is set per run by sim_m_case1_damping_comm (= -gain_nl (I-11'/n) w0
% S_BASE, the nonlinear realization of the paper's D^com = C K C').
%
% NOTE on exactness: block positions, colours and the per-converter injection
% reproduce the hand-tuned reference model exactly. LINE routing is autorouted
% (Simulink chooses the waypoints), so line paths may differ cosmetically.

if nargin < 1 || isempty(out_name), out_name = 'simulation_model_damping_comm'; end
base = 'simulation_model';
new  = out_name;                             % gain-agnostic: one .slx for all K
TUM_BLUE = '[0,0.396078,0.741176]';          % correct TUM primary blue #0065BD

% =================== per-converter Pdamp block positions (leaf subsystem -> from / sum)
% Exactly as hand-placed in the reference model.
PDAMP = {  % leaf, Pdamp_From pos, Pdamp_Sum pos
    'GFL1', [265 490 325 510], [345 462 375 493]
    'GFM2', [-5 585 55 605],   [220 572 250 603]
    'GFM3', [-60 515 0 535],   [65 492 95 523]
    'GFM4', [-115 515 -55 535],[-20 502 10 533]
    'GFL5', [330 465 390 485], [465 452 495 483]
    'GFL6', [315 465 375 485], [465 452 495 483]
    'GFM7', [-75 520 -15 540], [55 497 85 528]
    'GFM8', [-140 515 -80 535],[-45 502 -15 533]
    'GFM9', [-150 505 -90 525],[-50 482 -20 513]
};

% ================== existing upstream blocks repositioned by hand (rel path -> Position)
MOVES = {
    '/Area 1', [20 27 80 103]
    '/Area 1/INVERTER 1/GFL1/Constant', [270 460 300 480]
    '/Area 1/INVERTER 1/GFL1/Constant1', [405 530 440 550]
    '/Area 1/INVERTER 1/GFL1/From1', [400 561 445 579]
    '/Area 1/INVERTER 1/GFL1/From17', [400 441 450 459]
    '/Area 1/INVERTER 1/GFL1/From19', [400 381 450 399]
    '/Area 1/INVERTER 1/GFL1/From2', [400 501 445 519]
    '/Area 1/INVERTER 1/GFL1/From20', [400 411 450 429]
    '/Area 1/INVERTER 1/GFL1/From4', [400 591 440 609]
    '/Area 1/INVERTER 1/GFL1/Goto8', [765 486 840 504]
    '/Area 1/INVERTER 1/GFL1/Subsystem4', [510 370 640 620]
    '/Area 1/INVERTER 2/GFM2/Constant', [80 570 135 590]
    '/Area 1/INVERTER 2/GFM2/Constant1', [80 639 135 661]
    '/Area 1/INVERTER 2/GFM2/From18', [80 612 130 628]
    '/Area 1/INVERTER 2/GFM2/From51', [80 552 140 568]
    '/Area 1/INVERTER 2/GFM2/Gain2', [415 485 445 515]
    '/Area 1/INVERTER 2/GFM2/Goto30', [405 597 465 613]
    '/Area 1/INVERTER 2/GFM2/Goto31', [410 572 470 588]
    '/Area 1/INVERTER 2/GFM2/Goto32', [405 542 465 558]
    '/Area 1/INVERTER 2/GFM2/Omega', [480 493 510 507]
    '/Area 1/INVERTER 2/GFM2/VSM control', [285 547 370 663]
    '/Area 1/INVERTER 2/GFM2/theta_0', [420 658 450 672]
    '/Area 1/INVERTER 2/GFM2/theta_t', [420 623 450 637]
    '/Area 1/INVERTER 3/GFM3/Constant', [-60 490 -5 510]
    '/Area 1/INVERTER 3/GFM3/Constant1', [35 559 90 581]
    '/Area 1/INVERTER 3/GFM3/From18', [35 532 85 548]
    '/Area 1/INVERTER 3/GFM3/From51', [35 472 95 488]
    '/Area 1/INVERTER 3/GFM3/Gain2', [250 405 280 435]
    '/Area 1/INVERTER 3/GFM3/Goto30', [240 517 300 533]
    '/Area 1/INVERTER 3/GFM3/Goto31', [245 492 305 508]
    '/Area 1/INVERTER 3/GFM3/Goto32', [240 462 300 478]
    '/Area 1/INVERTER 3/GFM3/Omega', [315 413 345 427]
    '/Area 1/INVERTER 3/GFM3/VSM control', [120 467 205 583]
    '/Area 1/INVERTER 3/GFM3/theta_0', [255 578 285 592]
    '/Area 1/INVERTER 3/GFM3/theta_t', [255 543 285 557]
    '/Area 2', [910 25 965 105]
    '/Area 2/INVERTER 4/GFM4/Constant', [-175 500 -120 520]
    '/Area 2/INVERTER 4/GFM4/Constant1', [-40 569 15 591]
    '/Area 2/INVERTER 4/GFM4/From18', [-40 542 10 558]
    '/Area 2/INVERTER 4/GFM4/From51', [-40 482 20 498]
    '/Area 2/INVERTER 4/GFM4/Gain2', [175 415 205 445]
    '/Area 2/INVERTER 4/GFM4/Goto30', [165 527 225 543]
    '/Area 2/INVERTER 4/GFM4/Goto31', [170 502 230 518]
    '/Area 2/INVERTER 4/GFM4/Goto32', [165 472 225 488]
    '/Area 2/INVERTER 4/GFM4/Omega', [240 423 270 437]
    '/Area 2/INVERTER 4/GFM4/VSM control', [45 477 130 593]
    '/Area 2/INVERTER 4/GFM4/theta_0', [180 588 210 602]
    '/Area 2/INVERTER 4/GFM4/theta_t', [180 553 210 567]
    '/Area 2/INVERTER 5/GFL5/Constant', [390 450 420 470]
    '/Area 2/INVERTER 6/GFL6/Constant', [380 450 410 470]
    '/Area 3', [432 -120 518 -65]
    '/Area 3/INVERTER 7/GFM7/Constant', [-75 495 -20 515]
    '/Area 3/INVERTER 7/GFM7/Constant1', [25 564 80 586]
    '/Area 3/INVERTER 7/GFM7/From18', [25 537 75 553]
    '/Area 3/INVERTER 7/GFM7/From51', [25 477 85 493]
    '/Area 3/INVERTER 7/GFM7/Gain2', [240 410 270 440]
    '/Area 3/INVERTER 7/GFM7/Goto30', [230 522 290 538]
    '/Area 3/INVERTER 7/GFM7/Goto31', [235 497 295 513]
    '/Area 3/INVERTER 7/GFM7/Goto32', [230 467 290 483]
    '/Area 3/INVERTER 7/GFM7/Omega', [305 418 335 432]
    '/Area 3/INVERTER 7/GFM7/VSM control', [110 472 195 588]
    '/Area 3/INVERTER 7/GFM7/theta_0', [245 583 275 597]
    '/Area 3/INVERTER 7/GFM7/theta_t', [245 548 275 562]
    '/Area 3/INVERTER 8/GFM8/Constant', [-210 500 -155 520]
    '/Area 3/INVERTER 8/GFM8/Constant1', [-65 569 -10 591]
    '/Area 3/INVERTER 8/GFM8/From18', [-65 542 -15 558]
    '/Area 3/INVERTER 8/GFM8/From51', [-65 482 -5 498]
    '/Area 3/INVERTER 8/GFM8/Gain2', [150 415 180 445]
    '/Area 3/INVERTER 8/GFM8/Goto30', [140 527 200 543]
    '/Area 3/INVERTER 8/GFM8/Goto31', [145 502 205 518]
    '/Area 3/INVERTER 8/GFM8/Goto32', [140 472 200 488]
    '/Area 3/INVERTER 8/GFM8/Omega', [215 423 245 437]
    '/Area 3/INVERTER 8/GFM8/VSM control', [20 477 105 593]
    '/Area 3/INVERTER 8/GFM8/theta_0', [155 588 185 602]
    '/Area 3/INVERTER 8/GFM8/theta_t', [155 553 185 567]
    '/Area 3/INVERTER 9/GFM9/Constant', [-150 480 -95 500]
    '/Area 3/INVERTER 9/GFM9/Constant1', [-65 549 -10 571]
    '/Area 3/INVERTER 9/GFM9/From18', [-65 522 -15 538]
    '/Area 3/INVERTER 9/GFM9/From51', [-65 462 -5 478]
    '/Area 3/INVERTER 9/GFM9/Gain2', [150 395 180 425]
    '/Area 3/INVERTER 9/GFM9/Goto30', [140 507 200 523]
    '/Area 3/INVERTER 9/GFM9/Goto31', [145 482 205 498]
    '/Area 3/INVERTER 9/GFM9/Goto32', [140 452 200 468]
    '/Area 3/INVERTER 9/GFM9/Omega', [215 403 245 417]
    '/Area 3/INVERTER 9/GFM9/VSM control', [20 457 105 573]
    '/Area 3/INVERTER 9/GFM9/theta_0', [155 568 185 582]
    '/Area 3/INVERTER 9/GFM9/theta_t', [155 533 185 547]
    '/Gain', [695 -155 725 -125]
    '/Gain1', [695 -95 725 -65]
    '/Goto', [190 -52 275 -18]
    '/PSS model', [115 -50 145 -20]
    '/Scope', [875 -152 920 -68]
    '/Subsystem', [615 -152 655 -68]
    '/line 4', [450 170 500 240]
    '/line 5', [190 30 240 100]
    '/line 9', [710 30 760 100]
    '/powergui', [295 -152 378 -121]
};

% ============================================================ make the editable copy
close_all_quietly({base, new});
if exist([new '.slx'],'file'), delete([new '.slx']); end
load_system(base);
save_system(base, new);              % save-as renames the in-memory model to `new`
if ~bdIsLoaded(new), load_system(new); end

% =========================================================================
% PART 1 - ADD the damping-communication network (at the hand-tuned layout)
% =========================================================================
n = 9;
pdmap = containers.Map();
for i = 1:size(PDAMP,1), pdmap(PDAMP{i,1}) = struct('from',PDAMP{i,2},'sum',PDAMP{i,3}); end

% top-level blocks (positions exactly as hand-tuned)
muxIn = cell(1,n);
for k = 1:n
    muxIn{k} = add_block('simulink/Signal Routing/From', sprintf('%s/wcFrom%d',new,k), ...
        'MakeNameUnique','on','GotoTag',sprintf('w_c%d',k), ...
        'Position',[150 410+35*(k-1) 210 430+35*(k-1)]);
end
mux  = add_block('simulink/Signal Routing/Mux',  [new '/wcMux'], ...
                 'Inputs',num2str(n),'Position',[295 390 305 730]);
bias = add_block('simulink/Math Operations/Bias',[new '/wcBias'], ...
                 'Bias','-1','Position',[350 545 400 575]);            % Dw = w_c - 1
% CommGain: matrix gain = the workspace variable D_comm (gain-agnostic model).
gain = add_block('simulink/Math Operations/Gain',[new '/CommGain'], ...
                 'Gain','D_comm','Multiplication','Matrix(K*u)','Position',[415 540 510 580]);
lag  = add_block('simulink/Discrete/Memory',     [new '/CommLag'], ...
                 'InitialCondition','0','Position',[530 540 590 580]);
demux= add_block('simulink/Signal Routing/Demux',[new '/PdampDemux'], ...
                 'Outputs',num2str(n),'Position',[665 390 675 730]);
for k = 1:n
    add_block('simulink/Signal Routing/Goto', sprintf('%s/PdampGoto%d',new,k), ...
        'MakeNameUnique','on','GotoTag',sprintf('Pdamp_c%d',k),'TagVisibility','global', ...
        'BackgroundColor',TUM_BLUE,'Position',[795 410+35*(k-1) 865 430+35*(k-1)]);
end
% wiring (by port handle, so it is independent of the hand-tuned positions)
for k = 1:n, add_line(new, ph_out(muxIn{k}), ph_in(mux,k), 'autorouting','on'); end
add_line(new, ph_out(mux),  ph_in(bias,1), 'autorouting','on');
add_line(new, ph_out(bias), ph_in(gain,1), 'autorouting','on');
add_line(new, ph_out(gain), ph_in(lag,1),  'autorouting','on');
add_line(new, ph_out(lag),  ph_in(demux,1),'autorouting','on');
for k = 1:n
    gb = find_system(new,'SearchDepth',1,'BlockType','Goto','GotoTag',sprintf('Pdamp_c%d',k));
    add_line(new, ph_out(demux,k), ph_in(gb{1},1), 'autorouting','on');
end
fprintf('PART 1: added comm network (9 From -> Mux -> Bias -> Gain(D_comm) -> Memory -> Demux -> 9 Goto)\n');

% per-converter Pref + Pdamp_c{k} injection (Sum + From at the hand-tuned spots)
nfix = 0;
for k = 1:n
    g = find_system(new,'BlockType','Goto','GotoTag',sprintf('w_c%d',k));
    if isempty(g), warning('w_c%d Goto not found',k); continue; end
    invk = get_param(g{1},'Parent');                  % the 'INVERTER k' wrapper subsystem
    pref = find_pref_constant(invk);                  % Pref is nested in GFLx/GFMx below it
    if isempty(pref), warning('converter %d (%s): no Pref constant', k, oneline(invk)); continue; end
    leaf = regexp(get_param(pref,'Parent'),'[^/]+$','match','once');   % GFLx/GFMx, e.g. GFL1, GFM2
    if ~isKey(pdmap,leaf), error('no Pdamp position for converter leaf %s', leaf); end
    pp = pdmap(leaf);
    inject_pdamp(pref, k, TUM_BLUE, pp.from, pp.sum);
    nfix = nfix + 1;
    fprintf('  converter %d (%s): injected Pdamp_c%d\n', k, leaf, k);
end
fprintf('PART 1: injected damping into %d/%d converters\n', nfix, n);

% =========================================================================
% PART 2 - MOVE existing upstream blocks to the hand-tuned positions
% =========================================================================
nmoved = 0;
for i = 1:size(MOVES,1)
    b = [new MOVES{i,1}];
    if getSimulinkBlockHandle(b) < 0, warning('move target not found: %s', MOVES{i,1}); continue; end
    set_param(b,'Position',MOVES{i,2});
    nmoved = nmoved + 1;
end
fprintf('PART 2: repositioned %d/%d existing blocks\n', nmoved, size(MOVES,1));

% Match the upstream model's numerics: accelerator mode (the upstream
% simulation_model.slx runs in 'accelerator'). A C compiler is required for the
% MEX build; sim_m_case1_damping_comm unsets NoDefaultCurrentDirectoryInExePath
% so the Windows accelerator .bat build succeeds.
set_param(new,'SimulationMode','accelerator');
save_system(new);
fprintf('Saved %s.slx\n', new);
close_system(new,0);
end

% =========================================================================
function pref = find_pref_constant(invk)
% FIND_PREF_CONSTANT  Find the converter's active-power setpoint: a Constant
% whose Value is 'Pref' (fallback: value/name mentions pset / p_set / pref).
% Arguments:
%   invk  (char)  INVERTER subsystem path to search under
pref = '';
cs = find_system(invk,'LookUnderMasks','on','FollowLinks','off','BlockType','Constant');
for i = 1:numel(cs)
    v = oneline(get_param(cs{i},'Value'));
    if strcmpi(strtrim(v),'Pref'), pref = cs{i}; return; end
end
for i = 1:numel(cs)
    v = oneline(get_param(cs{i},'Value'));
    if ~isempty(regexpi(v,'pref|pset|p_set','once')), pref = cs{i}; return; end
end
end

function inject_pdamp(pref, k, tumblue, from_pos, sum_pos)
% INJECT_PDAMP  Splice a Pref + Pdamp_c{k} adjustment (Sum + From, TUM blue) onto
% the converter's Pref wire, so the active-power reference becomes Pref + Pdamp.
% Arguments:
%   pref      (char)    block path of the Pref constant whose output is rewired
%   k         (double)  converter index 1..9 (selects the Pdamp_c{k} From tag)
%   tumblue   (char)    RGB colour string for the adjustment blocks (TUM blue)
%   from_pos  (1x4)     Pdamp_From block position [x1 y1 x2 y2]
%   sum_pos   (1x4)     Pdamp_Sum block position [x1 y1 x2 y2]
parent = get_param(pref,'Parent');
po = get_param(pref,'PortHandles'); oline = po.Outport(1);
lh = get_param(oline,'Line');
dstPort = get_param(lh,'DstPortHandle');         % destination input port handle
if numel(dstPort) ~= 1 || dstPort < 0
    error('Pref of converter %d does not drive a single destination', k);
end
delete_line(lh);
% Pdamp_Sum / Pdamp_From are the per-converter "adjustment" blocks -> TUM blue,
% placed at the exact hand-tuned positions.
sumb = add_block('simulink/Math Operations/Sum', [parent '/Pdamp_Sum'], ...
                 'MakeNameUnique','on','Inputs','++','IconShape','rectangular', ...
                 'BackgroundColor',tumblue,'Position',sum_pos);
frb = add_block('simulink/Signal Routing/From', [parent '/Pdamp_From'], ...
                'MakeNameUnique','on','GotoTag',sprintf('Pdamp_c%d',k), ...
                'BackgroundColor',tumblue,'Position',from_pos);
% Re-assert the exact bounding box: add_block clamps a Sum block to a minimum
% height, so set the hand-tuned Position again on the constructed blocks.
set_param(sumb,'Position',sum_pos);
set_param(frb, 'Position',from_pos);
sp = get_param(sumb,'PortHandles');
add_line(parent, po.Outport(1),          sp.Inport(1), 'autorouting','on');
add_line(parent, ph_out(frb),            sp.Inport(2), 'autorouting','on');
add_line(parent, sp.Outport(1),          dstPort,      'autorouting','on');
end

% ===================================================================== small helpers
function h = ph_out(blk, k)
% PH_OUT  Return the handle of outport k (default 1) of a block.
% Arguments:
%   blk  (char/handle)              block path or handle
%   k    (double, optional, default 1)  outport index
if nargin<2, k=1; end; p=get_param(blk,'PortHandles'); h=p.Outport(k); end
function h = ph_in(blk, k)
% PH_IN  Return the handle of inport k (default 1) of a block.
% Arguments:
%   blk  (char/handle)              block path or handle
%   k    (double, optional, default 1)  inport index
if nargin<2, k=1; end; p=get_param(blk,'PortHandles'); h=p.Inport(k);  end
function s = oneline(s)
% ONELINE  Collapse newlines in a string to spaces (single-line printing).
% Arguments:
%   s  (char)  input string (may contain newlines)
s = strrep(strrep(s,newline,' '),char(10),' '); end
function close_all_quietly(names)
% CLOSE_ALL_QUIETLY  Close each loaded model without saving, ignoring errors.
% Arguments:
%   names  (cellstr)  model names to close if loaded
for i=1:numel(names)
    try, if bdIsLoaded(names{i}), close_system(names{i},0); end; catch, end
end
end
