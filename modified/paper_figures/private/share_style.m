function [c, lw] = share_style(share_pct, s)
% SHARE_STYLE  Line colour and width for one activation share of the sweep figures.
% Arguments:
%   share_pct  (double)  activation share in percent (0 = uncontrolled baseline)
%   s          (struct)  paper_style struct (colour and line-width fields)
%
% The 0 % baseline is emphasised red, every other share takes the sweep colormap
% colour. Red marks the uncontrolled case throughout the paper, so it must not sit
% inside the blue ramp.
if share_pct == 0
    c = s.red; lw = s.lw_dataemph;
else
    c = sweep_colormap(share_pct); lw = s.lw_data;
end
end
