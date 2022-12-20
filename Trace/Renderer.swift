//
//  Renderer.swift
//  Trace
//
//  Created by Tahmid Azam on 19/12/2022.
//

import SwiftUI
import simd
import CoreImage

struct Renderer: View {
    @Binding var doc: TraceDocument
    
    var size: CGSize
    var globalPotentialRange: ClosedRange<Double>
    var sampleIndex: Int
    
    var image: CGImage? {
        return nil
    }
    
    var body: some View {
        EmptyView()
    }
    
    var truePotentials: [TruePotential] {
        doc.contents.streams.compactMap { stream in
            guard let polarlocation = stream.electrode.location else {
                return nil
            }
            
            let cartesianLocation = polarlocation.cgPoint(in: size)
            let samplePotential = stream.samples[sampleIndex]
            
            return TruePotential(value: samplePotential, cartesianLocation: cartesianLocation)
        }
    }
    
    func color(of value: Double) -> Color {
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
    
    struct TruePotential {
        var value: Double
        var cartesianLocation: CGPoint
    }
    
    func distance(from a: CGPoint, to b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        
        let sum = pow(dx, 2) + pow(dy, 2)
        
        return sqrt(sum)
    }
    
    func potential(at point: CGPoint) -> Double {
        return truePotentials.map { truePotential in
            let dx = point.x - truePotential.cartesianLocation.x
            let dy = point.y - truePotential.cartesianLocation.y
            
            let sum = pow(dx, 2) + pow(dy, 2)
            
            return simd_fast_rsqrt(sum)
        }.reduce(0.0, +)
    }
}

