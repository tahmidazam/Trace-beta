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
#else
    // MARK: FUNCTIONS
    /// Calculates the colour to render a scalp map segment at a given index.
    /// - Parameter index: The index to calculate the color of.
    /// - Returns: The color to render the scalp map segment.
    func color(at index: Int, globalPotentialRange: ClosedRange<Double>) -> Color? {
        let value = samples[index]
        
        let positiveColors: [NSColor] = [NSColor(.green), NSColor(.yellow), NSColor(.red)]
        let negativeColors: [NSColor] = [NSColor(.green), NSColor(.cyan), NSColor(.blue)]
        
        if value >= 0 {
            let prop: Double = (value / globalPotentialRange.upperBound) * 100
            
            return Color(nsColor: positiveColors.intermediate(percentage: prop))
        } else {
            let prop: Double = (value / globalPotentialRange.lowerBound) * 100
            
            return Color(nsColor: negativeColors.intermediate(percentage: prop))
        }
    }
#endif
    func path(
        plotSize: CGSize,
        verticalPaddingProportion: Double,
        rowCount: Int,
        rowIndex: Int,
        globalPotentialRange: ClosedRange<Double>,
        firstSampleIndex: Int,
        plottingWindowSize: Int,
        pointsPerCGPoint: Int
    ) -> Path {
        
        let maxAbsolutePotential = max(abs(globalPotentialRange.lowerBound), abs(globalPotentialRange.upperBound))
    
        let rowHeight: CGFloat = (plotSize.height * (1 - verticalPaddingProportion)) / Double(rowCount)
        
        let minY = (plotSize.height * verticalPaddingProportion / 2) + rowHeight * CGFloat(rowIndex)
        
        
        let xStep = plotSize.width / CGFloat(plottingWindowSize - 1)
        
        print(xStep)
        
        let sampleIndexRange = (firstSampleIndex...(firstSampleIndex + plottingWindowSize - 1))
        
        let points: [CGPoint] = sampleIndexRange.enumerated().compactMap { index, sampleIndex in
            guard index.quotientAndRemainder(dividingBy: pointsPerCGPoint).remainder == 0 else { return nil }
            
            let potential = samples[sampleIndex]
            
            let x = xStep * CGFloat(index)
            
            let absolutePotential = abs(potential)
            let sign = potential / absolutePotential * -1
            let distanceFromEquilibrium = (potential / maxAbsolutePotential) * (rowHeight / 2)
            
            let y = (minY + rowHeight / 2) + (sign * distanceFromEquilibrium)
            
            if y.isNaN {
                return CGPoint(x: x, y: (minY + rowHeight / 2))
            } else {
                return CGPoint(x: x, y: y)
            }
        }
        
        let path = Path { path in
            path.addLines(points)
        }
        
        return path
    }
    
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
