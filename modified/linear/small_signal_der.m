function [Ass, ev, info] = small_signal_der(casefile)
% SMALL_SIGNAL_DER  Build the paper's small-signal stability matrix A^ss from a
% case .mat, using the DER inertia allocation m_der (hence "_der").
% Arguments:
%   casefile  (char)  case .mat path from build_linear_cases (reads m_der, d, L, Dcom to form A^ss)
%
% The SG inertia is excluded - that enters only the time-domain model - giving the
% clean structure-preserving block form
%
%   A^ss_0 = [ 0        I       ]   (D^com = 0,        Eq. Ass0)
%            [ -M^-1 L  -M^-1 D  ]
%   A^ss   = [ 0        I        ]  (D^eff = D + D^com, Eq. Ass)
%            [ -M^-1 L  -M^-1 D^eff]
%
%   [Ass, ev, info] = small_signal_der('cases/case_comm.mat')
%
% Governor-free (swing subset only - no turbine / droop / governor states).
% M = diag(m_der) is the DER inertia ALLOCATION (the paper's "M"); the two SGs'
% inertia is NOT included here - it enters only the time-domain COI model
% (simulate_linear.m), not the small-signal pole-placement matrix.
%
% Zero-inertia (GFL/droop) nodes: the allocation gives 3 of them m_i ~ 1e-10
% (effectively 0, buses 14/9/10). They are kept with their RAW tiny inertia, so
% M is invertible and the [0 I; -M^-1 L, -M^-1 D^eff] block structure is exact.
% Because m_i -> 0 with d_i > 0, each contributes ONE huge negative-real pole
% (~ -d_i/m_i ~ -1e8..-1e11): a first-order droop response, far in the LHP, with
% damping ratio 1, so it does NOT affect maxRe or zeta_min of the electro-
% mechanical modes (verified identical to the m->0 DAE-reduced limit). Those 3
% poles are off-axis; Fig. 4 (paper_figures/fig4_linear_eig) clips them.

S = load(casefile);
m = S.m_der(:);                               % M = DER allocation (paper's M; no SG inertia)
d = S.d(:); L = S.L; Dcom = S.Dcom; n = numel(m);
D = diag(d); Deff = D + Dcom;                 % D^eff (= D when Dcom = 0 -> A^ss_0)

Minv = diag(1./m); I = eye(n); Z = zeros(n);
Ass = [ Z,        I        ;
       -Minv*L,  -Minv*Deff ];                % Eq. Ass (A matrix for case small signal)
ev  = eig(Ass);

nonlinear  = abs(ev) < 1e4;                          % electromechanical modes (exclude huge droop poles)
info = struct('n',n,'nstate',2*n,'has_comm',any(Dcom(:)~=0), ...
              'em_modes',find(nonlinear),'droop_poles',ev(~nonlinear));
end
