//
//  Stream.swift
//  Trace
//
//  Created by Tahmid Azam on 07/08/2022.
//
//  Copyright (C) 2022 Tahmid Azam
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

import Foundation
import SwiftUI

/// The data structure of an electrode's data stream.
struct Stream: Identifiable, Codable, Hashable {
    var id = UUID()
    
    // MARK: PROPERTIES
    /// The electrode associated with the potential samples.
    var electrode: Electrode
    /// Array holding the potentials at each time step.
    var samples: [Double]
    
    // MARK: COMPUTED PROPERTIES
    /// The range of potentials in the stream.
    var potentialRange: ClosedRange<Double>? {
        guard let min = samples.min(), let max = samples.max() else {
            return nil
        }
        
        return min...max
    }
    
    #if os(iOS)
    // MARK: FUNCTIONS
    /// Calculates the colour to render a scalp map segment at a given index.
    /// - Parameter index: The index to calculate the color of.
    /// - Returns: The color to render the scalp map segment.
    func color(at index: Int, globalPotentialRange: ClosedRange<Double>) -> Color? {
        let value = samples[index]
        
        let positiveColors: [UIColor] = [UIColor(.green), UIColor(.yellow), UIColor(.red)]
        let negativeColors: [UIColor] = [UIColor(.green), UIColor(.cyan), UIColor(.blue)]
        
        if value >= 0 {
            let prop: Double = (value / globalPotentialRange.upperBound) * 100
            
            return Color(uiColor: positiveColors.intermediate(percentage: prop))
        } else {
            let prop: Double = (value / globalPotentialRange.lowerBound) * 100
            
            return Color(uiColor: negativeColors.intermediate(percentage: prop))
        }
    }
    #endif
    
    // MARK: STATIC FUNCTIONS
    /// Import samples of potentials from a text input.
    ///
    /// If the return value is nil, the text input is invalid, and cannot be parsed for samples of potentials.
    ///
    /// - Parameter string: The text input to import from.
    /// - Returns: Samples of potentials at each time step.
    static func samples(from string: String) -> [Double]? {
        let components = string.components(separatedBy: .whitespacesAndNewlines)
        let samples = components.compactMap { sample in
            return Double(sample)
        }
        
        // Ensuring all the samples are in a valid number format.
        guard components.count == samples.count else {
            return nil
        }

        return samples
    }
    /// Converts samples to a chart-parsable data structure.
    /// - Parameters:
    ///   - samples: Samples to map.
    ///   - sampleRate: Sample rate of the trace document.
    /// - Returns: A chart-parsable data structure.
    func sampleDataPoints(at sampleRate: Double) -> [Stream.SampleDataPoint] {
        var data: [Stream.SampleDataPoint] = []
        
        for sampleIndex in 0..<samples.count {
            let dataPoint = Stream.SampleDataPoint(
                timestamp: (1 / sampleRate) * Double(sampleIndex),
                potential: samples[sampleIndex]
            )
            
            data.append(dataPoint)
        }
        
        return data
    }
    
    // MARK: STRUCTURES
    /// A data structure suitable for parsing by charts.
    struct SampleDataPoint: Hashable, Identifiable {
        var id: Self { self }
        
        /// The x-axis time value.
        var timestamp: Double
        /// The y-axis potential value.
        var potential: Double
    }
}
