function c = sweep_colormap(share_pct)
% SWEEP_COLORMAP  Sweep colour for one activation share: the vik blue wing run from a
% light (but still visible) blue at 0 % to a dark blue at 100 %.
% Arguments:
%   share_pct  (double)  activation share in percent, clamped to [0,100]
%
% vik_wing reversed, so larger damped shares read as progressively darker blue. The
% pale centre of vik is skipped at one end and the warm half at the other, so the ramp
% never washes out and never turns black. Note that the 0 % baseline is NOT drawn in
% this ramp anywhere in the paper - share_style paints it red - so the light end only
% ever shows up on the colour bar, where draw_share_colorbar covers it with a red block.
persistent SUB
if isempty(SUB)
    SUB = flipud(vik_wing());     % light blue (0%) -> dark blue (100%)
end
t   = max(0, min(1, share_pct/100));
idx = 1 + round(t*(size(SUB,1)-1));
c   = SUB(idx, :);
end
