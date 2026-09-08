function s = paper_style(varargin)
% PAPER_STYLE  IEEE-paper-ready plot dimensions, fonts and colours.
% Arguments:
%   'column'    ('single'|'double', default 'single')  IEEE column width selector
%   'aspect'    (double, default 1.6)                  width/height ratio
%   'font'      (char, default 'Times')                text font family
%   'fontsize'  (double, default 8)                    base font size [pt]
%
%   s = paper_style()                         % single column, default aspect
%   s = paper_style('column','double')        % double-column figure
%   s = paper_style('aspect',1.4)             % override width/height
%   s = paper_style('column','single','aspect',1.0)  % square
%
% IEEE Transactions (two-column layout):
%   single-column figure width   3.5  inches
%   double-column figure width   7.16 inches
%   base font (body)             8 pt
%
% Returned struct fields are consumed by paper_figure / paper_axes /
% paper_export so a paper plot looks the same everywhere.
%
%   .width_in, .height_in   figure size [inches]
%   .font, .fontsize        text font + size
%   .lw_axis, .lw_data,     line widths for axes / data / emphasised
%       .lw_dataemph
%   .p301                   sweep colormap anchor (Pantone 301)
%   .red                    uncontrolled (K = 0) accent: p301 hue-rotated to red,
%                               so it carries the same weight as the blue
%   .gray                   neutral gray for gridlines etc.

p = inputParser;
p.addParameter('column','single', @(x) any(strcmpi(x,{'single','double'})));
p.addParameter('aspect',1.6, @isnumeric);
p.addParameter('font','Times');
p.addParameter('fontsize',8);
p.parse(varargin{:}); o = p.Results;

switch lower(o.column)
    case 'single', w = 3.5;        % IEEEtran single column
    case 'double', w = 7.16;       % IEEEtran double column
end
h = w / o.aspect;

s = struct( ...
    'column',       lower(o.column), ...
    'width_in',     w, ...
    'height_in',    h, ...
    'font',         o.font, ...
    'fontsize',     o.fontsize, ...
    'p301',         [0 82 147]/255, ...
    'red',          [147 0 0]/255, ...
    'gray',         [.55 .55 .55], ...
    'lw_axis',      0.6, ...
    'lw_data',      1.0, ...
    'lw_dataemph',  1.4 ...
);
end
