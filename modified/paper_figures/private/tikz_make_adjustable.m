function tikz_make_adjustable(tikzfile)
% TIKZ_MAKE_ADJUSTABLE  Rewrite a matlab2tikz .tikz so the styling that matters for
% an IEEE two column layout (fonts, the legend box, and the overall size) is driven
% by LaTeX macros instead of being baked into the file. The plotted data is never
% touched; only styling hooks are swapped in. Idempotent: a file that already carries
% the hooks is left unchanged, so it is safe to run from paper_export on every export
% and also as a one off over already exported files.
%
% The macros it introduces are given defaults in figures/paperfig_preamble.tex.
% Override any of them in the document preamble (or right before a given \input) to
% restyle every figure at once, without regenerating anything in MATLAB:
%   \figscale       uniform multiplier on every baked inch dimension (whole figure size)
%   \figfont        base font for the whole picture (tick labels, axis labels, nodes)
%   \figticfont     tick label font   (defaults to \figfont)
%   \figlabelfont   axis label font   (defaults to \figfont, set in the preamble)
%   \figtitlefont   axis title font   (defaults to \figfont, set in the preamble)
%   \figlegendfont  legend text font  (defaults to \figfont, set in the preamble)
%   \figcornerfont  bold corner tag font
%   \figlegendlw / \figlegendfill / \figlegenddraw   legend box stroke / fill / draw
%
%   tikz_make_adjustable('modified/paper_figures/figures/fig4_linear_eig.tikz')

txt = fileread(tikzfile);

% idempotency: the picture font hook below is our marker. If it is already present
% the file has been processed, so return without changing anything.
if contains(txt, '[font=\figfont')
    return
end

% ============ base font for the whole picture (covers every node, and, after the
% tick label fix below, the tick labels too). Handle a bare \begin{tikzpicture} as
% well as one that already carries options.
if contains(txt, sprintf('\\begin{tikzpicture}['))
    txt = strrep(txt, '\begin{tikzpicture}[', '\begin{tikzpicture}[font=\figfont,');
else
    txt = strrep(txt, '\begin{tikzpicture}', '\begin{tikzpicture}[font=\figfont]');
end

% ============ free the tick label font. matlab2tikz bakes font=\color{black} on the
% tick labels, which sets the colour but also pins the size; swap it for \figticfont
% so the size follows the knob. The labels stay black (the picture default colour).
txt = strrep(txt, 'font=\color{black}', 'font=\figticfont');

% ============ size knob: multiply every baked inch dimension by \figscale, so one
% macro scales widths, heights, and the multi panel offsets together. pgfplots
% evaluates width={\figscale*Xin} and at={(\figscale*Xin,...)} through pgfmath.
txt = regexprep(txt, 'width=([0-9.]+)in,',   'width={\\figscale*$1in},');
txt = regexprep(txt, 'height=([0-9.]+)in,',  'height={\\figscale*$1in},');
txt = regexprep(txt, 'at=\{\(([0-9.]+)in,([0-9.]+)in\)\}', ...
                     'at={(\\figscale*$1in,\\figscale*$2in)}');

% ============ legend box. Real matlab2tikz legends end their legend style with
% draw=black, fill=white}; the hand drawn per node legend uses a \draw with an
% explicit stroke. Route both through the same three knobs.
txt = strrep(txt, 'draw=black, fill=white}', ...
                  'draw=\figlegenddraw, fill=\figlegendfill, line width=\figlegendlw}');
txt = strrep(txt, '\draw[line width=0.6pt, fill=white, draw=black]', ...
                  '\draw[line width=\figlegendlw, fill=\figlegendfill, draw=\figlegenddraw]');

% ============ bold corner tag: keep it bold, take its size from \figfont.
txt = strrep(txt, 'font=\bfseries', 'font=\figcornerfont');

% ============ Fig. 7 zoom insets: lift their x tick numbers off the trace behind
% them. Unshifted, the 0 and the 0.4 sit on the settled COI trajectory of the panel
% underneath and the digits are cut (worst on Texas2000, whose trace runs highest).
% This is a label shift with no MATLAB counterpart, so it is applied here rather than
% left as a hand edit that the next export would drop. Scoped by filename, and the
% insets are picked out by their zoom window (the only axes in that figure that end at
% x = 0.5 s, see the zoom windows in fig7_coi_envelope_3cases). The count is asserted,
% so if the window ever changes this fails loudly instead of silently doing nothing.
if contains(tikzfile, 'fig7_coi_envelope')
    txt = shift_inset_x_ticks(txt, 'xmax=0.5,', 3);
end

% write back as raw bytes so the existing line endings are preserved
fid = fopen(tikzfile, 'w');
if fid < 0, error('tikz_make_adjustable:open', 'cannot write %s', tikzfile); end
fwrite(fid, txt, 'char');
fclose(fid);
end


% =========================================================================
function txt = shift_inset_x_ticks(txt, marker, expected)
% SHIFT_INSET_X_TICKS  Add \figinsettickshift to the x tick labels of every axis block
% whose options contain MARKER, and check that exactly EXPECTED blocks matched.
% Arguments:
%   txt       (char)    the whole .tikz
%   marker    (char)    option line that identifies the axes to shift
%   expected  (double)  how many of them there must be
PLAIN   = 'every x tick label/.append style={font=\figticfont}';
SHIFTED = 'every x tick label/.append style={font=\figticfont, yshift=\figinsettickshift}';
blocks  = regexp(txt, '(?s)\\begin\{axis\}\[.*?\\end\{axis\}', 'match');
hit = 0;
for b = 1:numel(blocks)
    head = extractBefore([blocks{b} ']'], ']');       % the option list only
    if ~contains(head, marker) || ~contains(head, PLAIN), continue; end
    txt = strrep(txt, blocks{b}, strrep(blocks{b}, PLAIN, SHIFTED));
    hit = hit + 1;
end
if hit ~= expected
    error('tikz_make_adjustable:insets', ...
          'expected %d inset axes matching "%s", found %d', expected, marker, hit);
end
end
