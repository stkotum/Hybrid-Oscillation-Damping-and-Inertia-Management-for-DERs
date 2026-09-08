function q = sector_spec()
% SECTOR_SPEC  The conic design region of [Feng et al., Thm. 1], drawn as dashed
% guides on both eigenvalue figures (Fig. 4 and Fig. 6).
%
%   Re(lambda) <= -beta          the vertical line
%   zeta       >= cos(zeta_max)  the damping cone, half-angle from cosZ
%
% One definition for both figures so they cannot drift apart.
q = struct('beta', 3, 'cosZ', 0.1);
q.sinZ = sqrt(1 - q.cosZ^2);
end
