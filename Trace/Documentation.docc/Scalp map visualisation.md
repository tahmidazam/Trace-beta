# Scalp map visualisation

How Trace renders electrodes on a 2-dimensional plane for visualising spatial patterns in potentials.

## Representing the scalp

Trace models the scalp as a set of concentric circles that act as a parallel to the actual distances between the electrodes. The actual distances are 10% or 20% of the total front-back or right-left distances of the skull, as outlined by the International 10-20 System.

In Trace's scalp map representation, each ring of electrode labels corresponds to a major percentage increment. From left-right, this system results in the following percentages:

Electrodes | Percentage of total left-right distance
---|---
`A2` to `T4` | 10% 
`T4` to `C4` | 20%
`C4` to `Cz` | 20%
`Cz` to `C3` | 20%
`C3` to `T3` | 20%
`T3` to `A1` | 10%

From nasion-inion (i.e, front-back), this system results in the following percentages:

Electrodes | Percentage of total nasion-inion (i.e, front-back) distance
---|---
`Fz` to `Cz` | 20%
`Cz` to `Pz` | 20%


## Constructing the components of the visualisation

### Placing electrode labels

Trace supports the International 10-20 System of electrode labelling and placement, which is documented in <doc:Electrode-support>. The ``Electrode/location`` computed property holds the general polar coordinate for the electrode label. The term *general* is used as the values inside ``Electrode/Polar/radius`` range from `0` to `1` and are factors by which the radius of the scalp the electrode is contained in should be multiplied by. The ``Electrode/Polar/cgPoint(in:)`` method converts the polar coordinate to a cartesian coordinate fit for drawing by a SwiftUI canvas.

### Drawing electrode areas

The areas for each electrode, with the exception of ``Electrode/Prefix-swift.enum/mastoid`` prefixed electrodes of suffix 1 or 2 (i.e., `A1` or `A2`), are truncated sectors with the maximum angle and a radius with 10% extension either way. Since the mastoid electrode lies on the 0% mark on the left-right scale (i.e, lies on the 'edge' of the scalp), it is drawn as a 10% extension onto the ``Electrode/Prefix-swift.enum/temporal`` prefixed electrodes of suffix 3 or 4 (i.e., `T3` or `T4`). The ``Electrode/sector(in:)`` method calculates the path for each electrode, ready to be drawn by a SwiftUI canvas.

### Coloring electrode areas

The areas for each electrode are coloured by how far through a gradient made of a group of ordered colors based on the potential's sign is sampled, which is proportional to the magnitude of the potential. The following table breaks down the positive and negative sets of colors:

Potential sign | Colors (in order of ascending magnitude)
---|---
`+` (positive) | `green`, `yellow`, `red`
`-` (negative) | `green`, `cyan`, `blue`

The ``Stream/color(at:globalPotentialRange:)`` returns the color of a stream at a given index. The other argument, globalPotentialRange, informs the function of the minimum and maximum potential of all samples in all streams in order to correctly scale color stop points in the gradient.

## See Also

