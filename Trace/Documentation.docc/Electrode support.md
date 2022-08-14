# Electrode support

How Trace represents the International 10-20 System of electrode placement on the scalp.

## The prefix-suffix pair

An electrode consists of a prefix ``Electrode/Prefix-swift.enum`` stored in ``Electrode/prefix-swift.property``, and a suffix integer stored in ``Electrode/suffix``. These two properties uniquely define an electrode:
- A ``Electrode/Prefix-swift.enum`` represents the area on the scalp the electrode is in, and are a parallel for the letters in the International 10-20 System's (IS) electrode labelling criteria (i.e., the prefix ``Electrode/Prefix-swift.enum/frontal`` is the 'Fp' in 'Fp1'). 
- The integer representing the suffix is a parallel for the number in the IS electrode labelling criteria. By convention, odd numbers represent the left side, even the right side, and 0, or the letter 'z' for 'zero', represents the central line down the scalp. 

> Tip: More information about the International 10-20 System can be found under the [Wikipedia entry](https://en.wikipedia.org/wiki/10–20_system_(EEG)).

In this way, an ``Electrode`` instance can be failably initialised either from an IS electrode label (e.g., the string 'Cz'), or from an explicitly argumented prefix-suffix pair.

## Electrode locations on-scalp

Electrode location data is used for rendering the 2-dimensional scalp map visualisations. Trace supports only certain suffixes of all prefixes:

Electrode prefix | International 10-20 System prefix symbol | Supported suffixes
---|---|---
`prefrontal` | Fp | 1, 2
`frontal` | F | 0 (z), 3, 4, 7, 8.
`temporal` | T | 3, 4, 5, 6
`parietal` | P | 0 (z), 3, 4.
`occipital` |O | 1, 2
`central` | C | 0 (z), 3, 4
`mastoid` | A | 1, 2

> Note: Electrodes that do not support location data will be omitted from the 2-dimensional sclap map visualisation in ``ScalpMapView`` but can be plotted on a chart in ``ChartView``.

## See Also
