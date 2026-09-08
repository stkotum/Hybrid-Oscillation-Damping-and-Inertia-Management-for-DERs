% FENG9_NONLINEAR_SETUP  (script) Populate the base workspace with all nonlinear model
% parameters for Scenario 1, identical to the upstream sim_m_case1.m, but
% WITHOUT loading a model, firing the breaker, or running a simulation. Call
% this from a runner script (it executes in the caller's workspace).
%
% Switch / disturbance schedule (upstream "long" scenario): GFM switch t=30 s,
% GFL switch t=35 s, 300 MW breaker t_brk=40 s (the model-default breaker time).
% Arguments: (none) - script; populates the base workspace

% ====================================================== reset rebuilt structs
% Defensive: clear struct arrays we (re-)build below so stale values from a
% previous OFF or ON setup (e.g. when run_smallexample_feng_paper runs OFF then ON
% inside the same MATLAB session) do not poison subsequent struct(k) = ...
% assignments with "subscripted assignment between dissimilar structures".
clear Init Init_GFL

load case_1_data.mat                   % solution.m / solution.d
m = solution.m; d = solution.d;
mpc = case_data;
t_gfm = 30; t_gfl = 35; t_brk = 40;    % upstream long schedule (matches sim_m_case1.m)

Sb = 100*10^6; fb = 60; wb = 2*pi*fb; Vb_h = 230*10^3;
trans_l = mpc.trans_l; line = mpc.line;

% ====================================================== GFM converter parameters (pu)
Vb_gfm = 20*10^3; Vb_p_ph = Vb_gfm*sqrt(2/3);
D_q_pu = 0.01; kp_vc_pu = 0.01; ki_vc_pu = 0.1; kp_i_pu = 0.3; ki_i_pu = 1;
r_f_pu = 0.01; c_f_pu = 0.05; l_f_pu = 0.09;

P_set = [6.000,7.100,2.000,5.700,3.000,2.200,5.000,7.000,2.000]*10^8;
Q_set = [0.743,1.449,0.897,0.364,0.224,-0.108,0.634,1.466,1.498]*10^8;
theta0 =[0.1781,0,-0.1848,-0.2946,-0.4565,-0.5202,-0.1629,-0.2615,-0.4725];

JDb = Sb/wb;
for k = 1:9
    J_pu = m(k)*Sb/JDb; D_p_pu = d(k)*Sb/JDb;
    P_set_pu_gfm(k) = P_set(k)/Sb; Q_set_pu_gfm(k) = Q_set(k)/Sb;
    [Vdc_gfm(k),P_set_gfm(k),Q_set_gfm(k),J_gfm(k),D_p_gfm(k),D_q_gfm(k),...
        kp_vc_gfm(k),ki_vc_gfm(k),kp_i_gfm(k),ki_i_gfm(k),r_f_gfm(k),c_f_gfm(k),l_f_gfm(k),Init(k)]...
        = fun00_GFM_pu_2_normial(Sb,Vb_gfm,fb,P_set_pu_gfm(k),Q_set_pu_gfm(k),J_pu,...
        D_p_pu,D_q_pu,kp_vc_pu,ki_vc_pu,kp_i_pu,ki_i_pu,r_f_pu,l_f_pu,c_f_pu);
    if m(k)>0.002, VSM(k)=1; else, VSM(k)=2; J_gfm(k)=0.001*Sb; end
    D_p_gfm_s(k) = d(k)*Sb;
end
for k = 1:9, Init(k).theta0 = theta0(k); end

% ====================================================== GFL converter parameters
kp_i_pu = 0.3; ki_i_pu = 10; kp_q_pu = 0.1; ki_q_pu = 1; kp_p_pu = 0.1; ki_p_pu = 1;
r_f_pu = 0.01; c_f_pu = 0.05; l_f_pu = 0.09;
gfl_idx = [1,5,6]; JDb = Sb/wb;
for k = 1:3
    kk = gfl_idx(k);
    p_set_pu(k) = P_set(kk)/Sb; v_set_pu(k) = 1; q_set_pu(k) = Q_set(kk)/Sb;
    Vb(k) = 20*10^3; m_gfl(k) = m(kk)*Sb; d_gfl(k) = d(kk)*Sb;
    w_pll = d_gfl(k)/m_gfl(k)/sqrt(2); ki_pll_pu = w_pll^2; kp_pll_pu = sqrt(2*ki_pll_pu);
    [Vdc(k),pset(k),qset(k),kp_pll(k),ki_pll(k),kp_i(k),ki_i(k),kp_q(k),ki_q(k),...
        kp_p(k),ki_p(k),r_f(k),c_f(k),l_f(k),Init_GFL(k)]...
        = fun00_GFL_pu_2_normial(Sb,Vb(k),fb,p_set_pu(k),q_set_pu(k),kp_pll_pu,ki_pll_pu,...
        kp_i_pu,ki_i_pu,kp_q_pu,ki_q_pu,kp_p_pu,ki_p_pu,r_f_pu,c_f_pu,l_f_pu);
    w_pll_s = d_gfl(k)/m_gfl(k)/sqrt(2); ki_pll_pu_s = w_pll_s^2; kp_pll_pu_s = sqrt(2*ki_pll_pu_s);
    [~,~,~,kp_pll_s(k),ki_pll_s(k),~,~,~,~,~,~,~,~,~,~]...
        = fun00_GFL_pu_2_normial(Sb,Vb(k),fb,p_set_pu(k),q_set_pu(k),kp_pll_pu_s,ki_pll_pu_s,...
        kp_i_pu,ki_i_pu,kp_q_pu,ki_q_pu,kp_p_pu,ki_p_pu,r_f_pu,c_f_pu,l_f_pu);
end
for k = 1:3, kk = gfl_idx(k); Init_GFL(k).theta0 = theta0(kk); end
