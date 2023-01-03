# Trace

A document-based, multi-platform SwiftUI application for viewing and editing EEG data, aimed at making software for viewing brain imaging data more accessible.

# Overview

## Trace for iOS

![Trace for iOS Preview](/Media/AppPreview.png)

View EEG data conveniently on your phone, with the same powerful functions as desktop alternatives. Use a 2-dimensional scalp map visualisation and effortlessly scrub through samples, or plot potentials over time for a graphic solution. Import multi-stream data from CSV or from text, and save and share your EEG data with the new minimal, space-efficient Trace document type, `.trace`.

## Trace for macOS

![Trace for macOS Preview](/Media/macOSAppPreview1.png)

![Trace for macOS Preview](/Media/macOSAppPreview2.png)

# Electrode support

Trace supports the International 10-20 system for labelling electrodes. Each electrode label is governed by a prefix and a suffix. 

Trace supports the following prefixes: prefrontal (Fp), frontal (F), temporal (T), parietal (P), occipital (O), central (C) and mastoid (A). The suffixes are integer values above 0, with even numbers corresponding to the right lobe of the brain, and odd numbers the left lobe. The number 0 refers to the central line on the scalp between the lobes, and is often written as the letter ‘z’. Examples of electrode labels include ‘Fp1’ or Cz’.

Electrode locations are used to construct the 2-dimensional scalp map visualisation, and the following indexes are supported:

- **prefrontal**: 1, 2.
- **frontal**: 0 (z), 3, 4, 7, 8.
- **temporal**: 3, 4, 5, 6.
- **parietal**: 0 (z), 3, 4.
- **occipital**: 1, 2.
- **central**: 0 (z), 3, 4.
- **mastoid**: 1, 2.

# Data import

Trace supports data import from `.csv` files and from text pasted into the app, and the file parsers have the following requirements:

- **CSV files**: each column represents a stream, with the first cell corresponding to the electrode label, and the rest of the cells form the array of samples. Each column (i.e., each stream) must have the same number of samples, and the electrode label must satisfy the format specified above.
- **text files**: newline-separated values.

# Compatability

**iOS**

Requires Xcode 14 (beta) or later and iOS 16 (beta) or later to install and run

# Contact

Want to submit feedback or request a feature? Email me at tahmid_azam@icloud.com, find me on Instagram with the tag [@tahmid.az](https://www.instagram.com/tahmid.az/) or on [LinkedIn](https://www.linkedin.com/in/tahmid-azam-90817818b/).

---

Copyright (C) 2022  Tahmid Azam

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.
