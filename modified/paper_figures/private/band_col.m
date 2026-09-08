function c = band_col(which)
% BAND_COL  Swing-band fill colour for the Fig. 5 envelopes, matched to the f_i ramps:
% a dusty red for the uncontrolled (K = 0) envelope and a near-white green for the
% controlled one.
% Arguments:
%   which  (char)  'off' (uncontrolled) | 'on' (controlled)
%
% The OUTER band is the darker of the two on purpose, so the controlled panel reads as
% a pale core sitting inside a heavy uncontrolled ring. The pair separates by
% brightness rather than by hue (relative luminance 0.48 against 0.93), which is what
% survives red-green colour blindness and greyscale print.
switch which
    case 'on', c = [238 252 235]/255;   % #EEFCEB - controlled envelope, near-white green
    otherwise, c = [224 171 171]/255;   % #E0ABAB - uncontrolled envelope, dusty red. Kept
                                        % light enough that the light end of the red
                                        % line_ramp still reads against it.
end
end
