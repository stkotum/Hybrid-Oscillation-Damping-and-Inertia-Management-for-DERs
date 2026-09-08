function build_linear_cases(gain)
% BUILD_LINEAR_CASES  Construct the paper-true linear small-signal model and write the
% two damping cases (OFF/ON) read by SIMULATE_LINEAR and SMALL_SIGNAL_DER.
% Arguments:
%   gain  (double, optional, default 20)  controller gain K = gain*I in D^com = C K C' [MW.s/rad]
%
% Notation (the paper's Sections 2 to 4):
%   M = diag(m) >0,  D = diag(d) >=0          inertia / damping allocation
%   L = L' >=0,  L 1 = 0                       reduced network matrix  (Eq.6-7)
%   P^u(t) = B^p * pbar * h(t)                 load step               (Sec.III-C)
%   P^com(t) = -D^com omega,  D^com = C K C'   communicated damping    (Eq. pcom_law)
%   D^eff = D + D^com                          effective damping       (Eq. Deff)
%   T^g pmdot = -p^m - R^-1 (S^g)' omega       nodal governor          (Eq. cl_gov)
%   P^mec = S^g p^m                            governor -> nodal power
%
% Two cases are written, identical except for the communicated layer:
%   cases/case_nocomm.mat : D^com = 0      (baseline allocation, "G^0")
%   cases/case_comm.mat   : D^com = C K C' (zero-sum communicated damping, "G")
%
% Paper-true modelling choices (paper Section 6.1), structure-
% preserving: units sit AT their network buses (no behind-reactance node),
% L is the Kron-reduced power-flow Jacobian, the two synchronous machines add
% their inertia at their buses (d_sg = 0), and the governor acts on the SG buses.

here   = fileparts(mfilename('fullpath'));
casedir = fullfile(here,'cases');
if ~exist(casedir,'dir'), mkdir(casedir); end
% ============================================================== constants
F0    = 60;            % nominal frequency [Hz]
WS    = 2*pi*F0;       % nominal angular frequency [rad/s]
BASE  = 100;           % system base [MVA]

% IMPORTANT: the DER swing nodes sit at the INVERTER buses, BEHIND their
% transformers [13 2 14 5 6 15 9 10 16] (the Fig.5 set) - NOT the grid buses
% [1 2 4 5 6 8 9 10 12]. The transformer reactance (trans_x ~ 0.0167 pu) is
% comparable to the lines, so placing the DERs on the grid side makes L too stiff
% and the electromechanical poles overshoot the desired region. Always check the
% network for converter/transformer buses before forming L.
NG     = [13 2 14 5 6 15 9 10 16];   % inverter buses (order matches solution.m)
SG_BUS = [13 6];                     % SGs co-located with GFL1 (bus 13) and GFL5 (bus 6)
n      = numel(NG);
H_SG    = 1.0;         % SG inertia constant [s]      (Section IV)
MFLOOR  = 0.1;         % floor for zero-inertia droop nodes (clean state space)
TAU_G   = 5.0;         % turbine time constant tau_i [s]
% Governor droop r^-1 per SG [MW.s/rad]. Paper value only:
%   sum r^-1 = 20      (Section IV)  -> COI settles ~ -0.12 Hz
RINV_G     = 20.0 / numel(SG_BUS);     % paper
DIST_BUS = 8;          % 300 MW load step at bus 8
DIST_MW  = 300;
% Communicated-damping gain K = GAIN*I [MW.s/rad]. CONSISTENCY WITH THE nonlinear:
% the nonlinear controller (build_feng9_nonlinear_comm) takes the SAME physical gain in
% MW.s/rad and converts it to its per-unit injection via S_base=100 MVA
% (gain_nl[pu] = GAIN / S_base). So GAIN here and gain_nl there are the same number.
% Default 20 MW.s/rad, the paper's K = 20 I (every driver passes it explicitly).
if nargin < 1 || isempty(gain), gain = 20.0; end
GAIN     = gain;

% ============================================================ M and D (Eq.ss)
% m_i, d_i from the hybrid allocation of [feng2025hybrid] (Scenario 1), stored
% per-unit on BASE -> multiply by BASE for MW.s^2/rad and MW.s/rad.
if exist('case_1_data.mat','file') ~= 2
    error('build_linear_cases:upstream', ['case_1_data.mat not found. It lives in the upstream ' ...
          'submodule: clone with --recurse-submodules or run "git submodule update --init", ' ...
          'and make sure upstream/ is on the MATLAB path (run_smallexample_feng_paper and ' ...
          'paper_config add it).']);
end
A = load('case_1_data.mat');
m = BASE * A.solution.m(:);          % inertia diagonal [MW.s^2/rad]
d = BASE * A.solution.d(:);          % damping diagonal [MW.s/rad]
m_der = m;                           % DER allocation only (no SG) -> A^ss_DER

% add the two synchronous machines' inertia at their buses (attributes ADD at a
% shared bus; SG damping d_sg = 0 so D is unchanged):  M_sg = 2 H S / w_s
m_sg = 2*H_SG*BASE/WS;               % per machine [MW.s^2/rad]
for b = SG_BUS, m(NG==b) = m(NG==b) + m_sg; end   % m = DER + SG, time-domain only (A^ss uses m_der, DER alone)
droop = m < 1e-3;                    % zero-inertia GFL/droop nodes (m ~ 1e-10, effectively 0)
% m is stored UNFLOORED. small_signal_der.m keeps the raw tiny m so the clean
% A^ss = [0 I; -M^-1 L, -M^-1 D^eff] block form holds (those nodes become huge
% negative-real poles, off-axis); simulate_linear.m floors them (MFLOOR) only so
% the time-domain closed-loop M is well-conditioned.

% =========================================== reduced network matrix L (Eq.6-7)
% Lossless power flow P_i = sum_j V_i V_j B_ij sin(th_i - th_j); linearize about
% the operating point -> Jacobian H_ij = -V_i V_j B_ij cos(th_i*-th_j*) (V=1),
% then Kron-eliminate the algebraic load buses:  L = H_GG - H_GL H_LL^-1 H_LG.
mpc = case_data;  nb = size(mpc.bus,1);   % network data from UPSTREAM (case_data); nb = number of buses
NL  = setdiff(1:nb, NG);             % algebraic load / passive buses (every bus that is not a DER node)
fb = mpc.branch(:,1); tb = mpc.branch(:,2); xb = mpc.branch(:,4);  % per-branch: from-bus, to-bus, reactance x [pu]

% =============================== DC susceptance matrix B (solves theta* only)
% b_ij = 1/x_ij assembled as a graph Laplacian (off-diag -b, diag +b), so that
% P = B*theta is the DC power flow (lossless, V=1, sin th ~= th). This B is just
% the solver for theta* below; the dynamic stiffness uses the cos-weighted H (c).
B = zeros(nb);
for k = 1:numel(fb)
    b = 1/xb(k); i = fb(k); j = tb(k);
    B(i,j)=B(i,j)-b; B(j,i)=B(j,i)-b; B(i,i)=B(i,i)+b; B(j,j)=B(j,j)+b;
end
% ============================= operating-point angles theta* (from upstream)
% theta0_G are the steady-state voltage angles at the 9 GRID generation buses,
% TAKEN FROM UPSTREAM: this is exactly the upstream load-flow solution (the same
% `theta0` array used by upstream sim_m_case1 / feng9_nonlinear_setup - the system's
% nominal stable operating point). They are GIVEN here, not recomputed.
theta0_G = [0.1781 0 -0.1848 -0.2946 -0.4565 -0.5202 -0.1629 -0.2615 -0.4725]';
% Only the grid gen buses have known angles, so pin those and DC-solve the rest
% (converter buses 13-16 behind their transformers, plus the load buses) so the
% whole theta* is self-consistent. The pinning is independent of the Kron split.
GRIDGEN = [1 2 4 5 6 8 9 10 12]; REST = setdiff(1:nb, GRIDGEN);   % known-angle buses vs solved-for buses
theta = zeros(nb,1); theta(GRIDGEN) = theta0_G;                   % pin the known (upstream) gen-bus angles
Pinj_R = -mpc.bus(REST,3)/BASE;                          % net injection at the solved buses [pu] (= -load; mpc.bus(:,3)=Pd demand)
theta(REST) = B(REST,REST) \ (Pinj_R - B(REST,GRIDGEN)*theta(GRIDGEN));   % DC balance B*theta = P -> theta(REST)

% ============================ synchronizing Jacobian H at theta* (Feng Eq.6)
% Same Laplacian assembly as B but weighted by cos(th_i*-th_j*): H_ij = -(1/x)cos(th_ij*)
% = dP/dtheta linearized about theta* (Feng Eq.6). H ~= B for small angle spreads;
% the cos(th_ij*) factors are what set where the eigenvalues land.
H = zeros(nb);
for k = 1:numel(fb)
    i=fb(k); j=tb(k); c = (1/xb(k))*cos(theta(i)-theta(j));
    H(i,j)=H(i,j)-c; H(j,i)=H(j,i)-c; H(i,i)=H(i,i)+c; H(j,j)=H(j,j)+c;
end
% ================================= Kron reduction onto the DER buses (Eq.7)
L = BASE * ( H(NG,NG) - H(NG,NL)*(H(NL,NL)\H(NG,NL)') );  % [MW/rad]
L = 0.5*(L+L');                                          % symmetrize (Eq: L = L'); Kron already gives L 1 = 0

% ======================================== governor selection S^g, T^g, R^-1
% Nodal governor (Eq. cl_gov): one state per governed machine (the two SGs).
% S^g in R^{n x ng} maps governor states to nodal injections P^mec = S^g p^m.
ng = numel(SG_BUS);
Sg = zeros(n, ng);
for c = 1:ng, Sg(NG==SG_BUS(c), c) = 1; end             % selection columns e_{i}
Tg = diag(repmat(TAU_G, ng,1));                          % T^g = diag(tau_i)  [s]
% R^-1 = diag(r_i^-1) is set per governor variant in the save loop below.

% ================================================== load step  P^u = B^p pbar
% 300 MW load increase at bus 8 -> net injection -300 MW. B^p is the (unit) nodal
% distribution, pbar the signed scalar magnitude (Eq. cl_BC).
if any(NG==DIST_BUS)
    Bp = double(NG(:)==DIST_BUS);                        % bus retained: direct e_{bus8}
else
    eL = double(NL(:)==DIST_BUS);                        % unit injection at bus 8 (eliminated)
    Bp = -H(NG,NL)*(H(NL,NL)\eL);                        % Kron transfer to retained nodes (1'Bp=1)
end
pbar = -DIST_MW;                                         % [MW]  (load increase)

% ========================================= communicated damping  D^com = C K C'
% Channel matrix C (Eq. C_neutral: 1'C = 0, aggregate-neutral) and gain K>=0
% (Eq. pcom_law). Full-communication zero-sum design: C spans the zero-mean
% subspace, C = I - 11'/n (symmetric idempotent, 1'C = 0). With K = GAIN*I,
% D^com = C K C' = GAIN (I - 11'/n) is symmetric PSD with 1'D^com = 0', so the
% communicated layer is zero-sum and leaves the aggregate COI untouched.
C    = eye(n) - ones(n)/n;          % aggregate-neutral channel  (1'C = 0)
K    = GAIN*eye(n);                 % proportional gain  K >= 0
Dcom_on  = C*K*C';                  % communicated damping operator  D^com
Dcom_off = zeros(n);                % baseline: no communicated layer

% ============================================================= meta / save
meta = struct('f0',F0,'base',BASE,'NG',NG,'sg_bus',SG_BUS,'m_sg',m_sg, ...
              'mfloor',MFLOOR,'dist_bus',DIST_BUS,'dist_mw',DIST_MW,'gain',GAIN, ...
              'tau_g',TAU_G,'placement','converter', ...
              'note','paper-true closed-loop (Eq. cl_A); DER nodes at inverter buses; see build_linear_cases.m');
names = arrayfun(@(b) sprintf('bus %d',b), NG, 'UniformOutput',false);
msig_fl = sum(max(m,MFLOOR));        % total inertia used by the (floored) time-domain

% Write the two paper cases (identical except for D^com):
%   case_nocomm.mat   paper governor (sum r^-1 = 20), D^com = 0      (baseline G^0)
%   case_comm.mat     paper governor (sum r^-1 = 20), D^com = C K C' (controller G)
Rinv = diag(repmat(RINV_G, ng, 1));                       % R^-1 = diag(r_i^-1)
meta.rinv_g = RINV_G; meta.gov = 'paper';
fprintf('[build_linear_cases] DER nodes at inverter buses NG=[%s]\n', num2str(NG));
fprintf('  n=%d DER (%d droop/zero-inertia: buses [%s]), ng=%d governed SGs at [%s]\n', ...
        n, sum(droop), num2str(NG(droop)), ng, num2str(SG_BUS));
fprintf('  m_tot = %.4f MW.s^2/rad true (%.4f floored, incl. 2 x m_sg=%.4f), d_tot = %.4f MW.s/rad\n', ...
        sum(m), msig_fl, m_sg, sum(d));
save_case(fullfile(casedir,'case_nocomm.mat'), m,m_der,d,L,Sg,Tg,Rinv,Bp,pbar,Dcom_off,C,K,droop,names,meta);
save_case(fullfile(casedir,'case_comm.mat'  ), m,m_der,d,L,Sg,Tg,Rinv,Bp,pbar,Dcom_on ,C,K,droop,names,meta);
fprintf('  [paper] tau=%g s, sum r^-1 = %7.2f MW.s/rad -> endpoint %+.4f Hz ; wrote case_{nocomm,comm}.mat\n', ...
        TAU_G, ng*RINV_G, (ones(1,n)*Bp*pbar)/(sum(d)+ng*RINV_G)/(2*pi));
fprintf('  analytic RoCoF (Thm 1, gov-independent) = 1''B^p pbar / m_sig = %+.4f Hz/s\n', ...
        (ones(1,n)*Bp*pbar)/msig_fl/(2*pi));
end

% =========================================================================
function save_case(fname, m,m_der,d,L,Sg,Tg,Rinv,Bp,pbar,Dcom,C,K,droop,names,meta) %#ok<INUSL>
% SAVE_CASE  Write one case .mat holding all model matrices under their paper names.
% Arguments:
%   fname               (char)   output .mat path
%   m, m_der, d         (n x 1)  inertia (DER+SG), DER-only inertia, damping diagonals
%   L                   (n x n)  reduced network matrix
%   Sg, Tg, Rinv                 governor selection / turbine time const / droop
%   Bp, pbar                     load-step nodal distribution and scalar magnitude
%   Dcom, C, K          (n x n)  communicated damping D^com and its factors C, K
%   droop, names, meta           zero-inertia mask, node names, metadata struct
save(fname, 'm','m_der','d','L','Sg','Tg','Rinv','Bp','pbar','Dcom','C','K','droop','names','meta');
end
