# Scientific colour maps (Crameri)

256-sample colour maps from Fabio Crameri's *Scientific colour maps* -
perceptually uniform and colour-vision-deficiency friendly.

- `vik.txt`   - diverging blue-white-red. Used by `sweep_colormap.m`, which takes
  only its blue wing as a light-blue -> dark-blue sweep ramp (no white centre, no
  orange).
- `imola.txt` - sequential blue->green->yellow (kept vendored; an earlier sweep
  option extended to TUM blue/green).

The per-bus f_i line colours (`line_ramp.m`) reuse vik's blue wing hue-rotated to
green (controlled) and red (uncontrolled) - the same light->dark style as the blue
sweep ramp.

Source: https://www.fabiocrameri.ch/colourmaps/ (MATLAB File Exchange #68546
"crameri"). The RGB text files here are taken from the cmcrameri distribution
(github.com/callumrollo/cmcrameri), MIT-licensed.

Please cite when used:
- Crameri, F. (2018). Scientific colour maps. Zenodo. doi:10.5281/zenodo.1243862
- Crameri, F., Shephard, G.E. & Heron, P.J. (2020). The misuse of colour in
  science communication. Nature Communications 11, 5444.
  doi:10.1038/s41467-020-19160-7
