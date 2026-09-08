function R = simulate_linear(casefile, varargin)
% SIMULATE_LINEAR  Integrate the paper-true closed-loop linear model for one case.
% Arguments:
%   casefile  (char)        case .mat path from build_linear_cases (holds m, d, L, Dcom, Sg, Tg, Rinv, Bp, pbar, meta)
%   varargin  (name-value)  t_end=20 [s], dt=2e-3 [s], t_event=2 [s]
%
%   R = simulate_linear('cases/case_comm.mat')
%   R = simulate_linear(casefile, 't_end',20, 'dt',2e-3, 't_event',2)
%
% Loads M = diag(m), D = diag(d), L, D^com, the nodal governor (S^g,T^g,R^-1) and
% the load step (B^p, pbar) from CASEFILE, then assembles and integrates the
% closed-loop state-space of the paper (sections 03-04, Eq. cl_A):
%
%   state  x = [ theta ; omega ; p^m ]
%   theta_dot = omega
%   M omega_dot = -L theta - D^eff omega + S^g p^m + B^p pbar h(t)
%   T^g p^m_dot = -p^m - R^-1 (S^g)' omega          ,  D^eff = D + D^com
%
% Here T^g = diag(tau_i) is the matrix of per-node TURBINE TIME CONSTANTS, the
% feng paper's tau (Eq. governor_coi / cl_gov, Sec. 02-03). The scalar COI governor
% 1/tau (-p^m_Sigma - r^-1 w_COI) is the aggregation of this nodal form. In the
% feng9 case tau = 5 s on the two SG buses; the droop gains R^-1 = diag(r_i^-1)
% satisfy Sum r^-1 = 20.

p = inputParser;
p.addParameter('t_end',20); p.addParameter('dt',2e-3); p.addParameter('t_event',2);
p.parse(varargin{:}); o = p.Results;

S = load(casefile);
m = S.m(:); d = S.d(:); L = S.L; Dcom = S.Dcom;
% Governor / turbine triple (paper Eq. cl_gov, Sec. 03):  T^g p^m_dot = -p^m - R^-1 (S^g)' omega
%   Sg   = S^g   selection matrix mapping the ng governor states onto their swing buses
%   Tg   = T^g   = diag(tau_i): per-node TURBINE TIME CONSTANTS (the paper's tau; feng9: 5 s
%                  on the two SG buses). Larger tau -> slower mechanical-power response.
%   Rinv = R^-1  = diag(r_i^-1): governor droop gains (the paper's r^-1; feng9: Sum r^-1 = 20).
Sg = S.Sg; Tg = S.Tg; Rinv = S.Rinv; Bp = S.Bp(:); pbar = S.pbar;
f0 = S.meta.f0; n = numel(m); ng = size(Sg,2);

% Time-domain closed-loop needs M invertible, so the zero-inertia droop nodes
% get a tiny floor here (only for integration). The EIGENVALUE matrix below uses
% small_signal_der.m, which instead eliminates those nodes algebraically (no floor).
mfl = m; mfl(m < 1e-3) = S.meta.mfloor;

% ======================================== define matrices (paper notation)
M    = diag(mfl);          Minv = diag(1./mfl);   % M = diag(m_i) inertia [MW s^2/rad], floored mfl so M^-1 exists (time-domain only)
D    = diag(d);                                   % D = diag(d_i) native (built-in) nodal damping [MW s/rad], before D^com  (Eq.ss)
Deff = D + Dcom;                                  % effective damping  D^eff = D + D^com  (Eq.Deff)
Tinv = diag(1./diag(Tg));                         % (T^g)^-1 = diag(1/tau_i)  (governor block of Eq.cl_A)
msig = sum(mfl);                                  % m_sigma = 1'M1  (Eq.coi_def)
wcoi_wt = (mfl.'/msig);                           % w' = 1'M / m_sigma  (mass-weighted COI)

I = eye(n); Znn = zeros(n); Zng = zeros(n,ng); Zgn = zeros(ng,n); Zg1 = zeros(ng,1);

% ===== small-signal stability matrix A^ss, built directly from the case .mat
% (Eq. Ass / Ass0, governor-free, droop nodes DAE-eliminated, M = DER allocation).
[Ass, ev] = small_signal_der(casefile);

% ================================== full closed-loop matrix A  (Eq. cl_A)
%     [    0          I            0     ]
% A = [ -M^-1 L    -M^-1 D^eff   M^-1 S^g ]
%     [    0      -T^-1 R^-1 (S^g)'  -T^-1 ]
A = [ Znn,        I,             Zng        ;
     -Minv*L,    -Minv*Deff,     Minv*Sg    ;
      Zgn,       -Tinv*Rinv*Sg', -Tinv      ];

% input  B = [0 ; M^-1 B^p ; 0]    (load step forcing  B^p pbar, Eq. cl_BC)
Bvec = [ zeros(n,1) ; Minv*Bp ; Zg1 ];
% COI output  C_coi = [0 , 1'M/m_sigma , 0]   ->  omega_COI = C_coi x
Ccoi = [ zeros(1,n) , wcoi_wt , zeros(1,ng) ];

% ============= integrate the step response with an ODE integrator (x(0)=0)
% Forcing switches on at t_event; integrate the post-event LTI system from rest.
nx = 2*n + ng;                                    % total state dimension: theta(n) + omega(n) + p^m(ng)
tt = (0:o.dt:o.t_end)';                           % output time grid 0:dt:t_end (column), the reported sample instants
fpost = Bvec*pbar;                                % constant forcing for t >= t_event
post = tt(tt >= o.t_event) - o.t_event;           % local time after the step
odef = @(t,x) A*x + fpost;                        % post-event RHS  x_dot = A x + B pbar (t unused: forcing is constant)
opts = odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',o.dt);  % tight tols; cap step at dt so fast modes are resolved
[~, Xp] = ode15s(odef, [-eps; post(2:end)], zeros(nx,1), opts);   % x(0)=0 at the step (ode15s: stiff system)
X = zeros(numel(tt), nx);                         % full-grid trajectory, preallocated to 0 (pre-step rest state)
X(tt >= o.t_event, :) = Xp;                       % zeros before the step (deviation coords)

% ===================================================================== channels
theta = X(:,1:n);                                 % nodal angle deviation [rad] (state cols 1:n)
omega = X(:,n+1:2*n);                             % nodal frequency deviation [rad/s] (state cols n+1:2n)
% state cols 2n+1:end are the ng governor (turbine mechanical-power) states p^m - not needed below, so not sliced out.
wcoi  = X*Ccoi.';                                 % COI frequency deviation [rad/s]
fcoi  = f0 + wcoi/(2*pi);                         %COI absolute [Hz]
frel  = (omega - wcoi)/(2*pi);                    % per-node relative-to-COI [Hz]
fabs  = f0 + omega/(2*pi);                        % per-node absolute [Hz]
rocof = gradient(wcoi/(2*pi), o.dt);              % COI RoCoF [Hz/s]

% ======== analytic limits (paper Theorems 1-2; independent of L, D^com, T^g)
rocof0   = (ones(1,n)*Bp*pbar)/msig/(2*pi);                       % Eq. rocof (Thm 1)
endpoint = (ones(1,n)*Bp*pbar)/(sum(d)+sum(diag(Rinv)))/(2*pi);    % Eq. ss    (Thm 2)

% ============ transfer function  G(s) = C_coi (sI-A)^-1 B  (Eq. cl_tf)
% Kept for interactive use only (nothing in the figure pipeline reads R.G), so the
% Control System Toolbox is optional: without it R.G is empty.
if exist('ss','class') == 8 || exist('ss','file') == 2
    G = ss(A, Bvec, Ccoi, 0);
else
    G = [];
end

% ================== small-signal region report (beta=3, cos zeta=0.1)
evn  = ev(abs(ev) > 1e-4);          % non-rigid modes: drop the rigid omega = theta_dot mode at lambda ~ 0
zeta = -real(evn)./abs(evn);        % damping ratio of each mode, zeta = -Re(lambda)/|lambda| (cone test: zeta >= cos zeta = 0.1)

% =========================================================================
% OUTPUT RECORDER - assemble the struct R returned to the caller.
% Nothing below alters the simulation; it just collects everything callers
% (plotters, sweeps, validation) might want into one struct so they don't
% have to recompute it. Grouped into: run metadata, the model matrices used,
% the assembled systems, the time-domain channels, and scalar summary metrics.
% =========================================================================
R = struct();
% run metadata
R.tt=tt; R.t_event=o.t_event; R.f0=f0; R.NG=S.meta.NG; R.names={S.names{:}};      % time grid, step instant, base freq f0, #SGs, node names
% model matrices used (paper notation)
R.m=m; R.d=d; R.L=L; R.Dcom=Dcom; R.Deff=Deff; R.Sg=Sg; R.Tg=Tg; R.Rinv=Rinv;     % inertia, native damping, Laplacian, D^com, D^eff, governor triple
% assembled systems
R.A=A; R.Ass=Ass; R.Bvec=Bvec; R.Ccoi=Ccoi; R.G=G; R.ev=ev;                       % full closed-loop A, swing-only A^ss, input B, COI output, transfer G, eig(A^ss)
% time-domain channels (rows = time samples tt, cols = nodes)
R.theta=theta; R.omega=omega; R.wcoi=wcoi; R.fcoi=fcoi; R.frel=frel; R.fabs=fabs; R.rocof=rocof;  % angles, freqs, COI freq, COI abs[Hz], per-node rel/abs[Hz], RoCoF
% small-signal sector metrics (Theorem 1 region: Re <= -beta, zeta >= cos zeta)
R.maxRe=max(real(evn)); R.minZeta=min(zeta);                                      % rightmost non-rigid pole real part, and minimum damping ratio
% analytic limits (Theorems 1-2, closed form)
R.rocof_analytic=rocof0; R.endpoint_analytic=endpoint;                            % predicted initial RoCoF and steady-state COI offset
% scalar time-domain summaries (all relative to f0)
[R.nadir, i_nadir] = min(fcoi - f0);                                              % COI nadir [Hz] and its sample
R.t_nadir = tt(i_nadir) - o.t_event;                                              % time of the nadir since the step [s]
R.steady=fcoi(end)-f0; R.rocof_max=max(abs(rocof));                               % final COI offset[Hz], peak |RoCoF|[Hz/s]
R.has_comm = any(Dcom(:)~=0);                                                     % true if communicated damping D^com is active (ON case)
end
