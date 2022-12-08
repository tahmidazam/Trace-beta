//
//  Electrode.swift
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

/// The data structure for identifying an electrode.
struct Electrode: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    
    // MARK: PROPERTIES
    /// The lobe/area of the brain associated with the electrode position.
    var prefix: Prefix
    /// The index associated with the electrode position, with a range from 0 to 8 inclusive.
    var suffix: Int
    
    // MARK: INITS
    init(prefix: Prefix, suffix: Int) {
        self.prefix = prefix
        self.suffix = suffix
    }
    /// Initialises an electrode from a string.
    /// - Parameter symbol: The symbol of the electrode as a string.
    init?(from symbol: String) {
        var prefix: Prefix? = nil
        var suffix: Int? = nil
        
        let suffixCharacter = symbol.suffix(1)
        
        guard !suffixCharacter.isEmpty else { return nil }
        
        if suffixCharacter == "z" {
            suffix = 0
        } else {
            suffix = Int(suffixCharacter)
        }
        
        switch symbol.dropLast(1) {
        case "Fp": prefix = Prefix.prefrontal
        case "F": prefix = Prefix.frontal
        case "T": prefix = Prefix.temporal
        case "P": prefix = Prefix.parietal
        case "O": prefix = Prefix.occipital
        case "C": prefix = Prefix.central
        case "A": prefix = Prefix.mastoid
        default: return nil
        }
        
        guard let prefix else { return nil }
        guard let suffix else { return nil }
        
        self.prefix = prefix
        self.suffix = suffix
    }
    
    // MARK: COMPUTED PROPERTIES
    /// Returns the general area of the electrode on the scalp as a ``GeneralArea-swift.enum``.
    var generalArea: GeneralArea {
        if suffix == 0 {
            return .central
        } else if suffix.quotientAndRemainder(dividingBy: 2).remainder == 1 {
            return .left
        } else {
            return .right
        }
    }
    /// The symbol of the electrode.
    ///
    /// Each symbol has two components, the prefix and suffix. The suffix is the last letter, and is either "z" for 0, or a number. The rest of the symbol is the prefix, and is a shorthand symbol for the lobe/area corresponding to the electrode placement on scalp.
    ///
    var symbol: String {
        "\(self.prefix.symbol)\(self.suffix == 0 ? "z" : "\(self.suffix)")"
    }
    /// A prose description of the location of the electrode on the scalp.
    ///
    /// The location description consists of two parts, the general area of the brain, followed by the prefix, which is more specific.
    ///
    var locationDescription: String {
        "\(self.generalArea) \(self.prefix.rawValue)"
    }
    /// Finds the polar coordinates of the electrode location on the scalp.
    ///
    /// Will return `nil` if the location is not supported by Trace.
    ///
    var location: Polar? {
        switch prefix {
        case .prefrontal:
            switch suffix {
            case 1: return Polar(radius: 4 / 5.5, angle: 0.05)
            case 2: return Polar(radius: 4 / 5.5, angle: 0.95)
            default: return nil
            }
        case .frontal:
            switch suffix {
            case 0: return Polar(radius: 2 / 5.5, angle: 0.0)
            case 3: return Polar(radius: 2 / 5.5, angle: 0.875)
            case 4: return Polar(radius: 2 / 5.5, angle: 0.125)
            case 7: return Polar(radius: 4 / 5.5, angle: 0.85)
            case 8: return Polar(radius: 4 / 5.5, angle: 0.15)
            default: return nil
            }
        case .temporal:
            switch suffix {
            case 3: return Polar(radius: 4 / 5.5, angle: 0.75)
            case 4: return Polar(radius: 4 / 5.5, angle: 0.25)
            case 5: return Polar(radius: 4 / 5.5, angle: 0.65)
            case 6: return Polar(radius: 4 / 5.5, angle: 0.35)
            default: return nil
            }
        case .parietal:
            switch suffix {
            case 0: return Polar(radius: 2 / 5.5, angle: 0.5)
            case 3: return Polar(radius: 2 / 5.5, angle: 0.625)
            case 4: return Polar(radius: 2 / 5.5, angle: 0.375)
            default: return nil
            }
        case .occipital:
            switch suffix {
            case 1: return Polar(radius: 4 / 5.5, angle: 0.45)
            case 2: return Polar(radius: 4 / 5.5, angle: 0.55)
            default: return nil
            }
        case .central:
            switch suffix {
            case 0: return Polar(radius: 0 / 5.5, angle: 0.0)
            case 3: return Polar(radius: 2 / 5.5, angle: 0.75)
            case 4: return Polar(radius: 2 / 5.5, angle: 0.25)
            default: return nil
            }
        case .mastoid:
            switch suffix {
            case 1: return Polar(radius: 6 / 5.5, angle: 0.75)
            case 2: return Polar(radius: 6 / 5.5, angle: 0.25)
            default: return nil
            }
        }
    }
    
    // MARK: FUNCTIONS
    /// Calculates the sector of the scalp associated with the electrode in a given domain and range.
    /// - Parameter size: The domain and range to draw the sector in.
    /// - Returns: The path of the sector.
    func sector(in size: CGSize) -> Path? {
        switch prefix {
        case .prefrontal:
            switch suffix {
            case 1: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0, eA: 0.1)
            case 2: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0.9, eA: 0)
            default: return nil
            }
        case .frontal:
            switch suffix {
            case 0: return Electrode.path(size: size, eR: 3 / 5.5, sR: 1 / 5.5, sA: 0.9375, eA: 0.0625)
            case 3: return Electrode.path(size: size, eR: 3 / 5.5, sR: 1 / 5.5, sA: 0.8125, eA: 0.9375)
            case 4: return Electrode.path(size: size, eR: 3 / 5.5, sR: 1 / 5.5, sA: 0.0625, eA: 0.1875)
            case 7: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0.8, eA: 0.9)
            case 8: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0.1, eA: 0.2)
            default: return nil
            }
        case .temporal:
            switch suffix {
            case 3: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0.7, eA: 0.8)
            case 4: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0.2, eA: 0.3)
            case 5: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0.6, eA: 0.7)
            case 6: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0.3, eA: 0.4)
            default: return nil
            }
        case .parietal:
            switch suffix {
            case 0: return Electrode.path(size: size, eR: 3 / 5.5, sR: 1 / 5.5, sA: 0.4375, eA: 0.5625)
            case 3: return Electrode.path(size: size, eR: 3 / 5.5, sR: 1 / 5.5, sA: 0.5625, eA: 0.6875)
            case 4: return Electrode.path(size: size, eR: 3 / 5.5, sR: 1 / 5.5, sA: 0.3125, eA: 0.4375)
            default: return nil
            }
        case .occipital:
            switch suffix {
            case 1: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0.4, eA: 0.5)
            case 2: return Electrode.path(size: size, eR: 5 / 5.5, sR: 3 / 5.5, sA: 0.5, eA: 0.6)
            default: return nil
            }
        case .central:
            switch suffix {
            case 0:
                let r = min(size.height, size.width) * (1 / 5.5)
                return Path.init(ellipseIn: CGRect(x: (size.width / 2) - (r / 2), y: (size.height / 2)  - (r / 2), width: r, height: r))
            case 3: return Electrode.path(size: size, eR: 3 / 5.5, sR: 1 / 5.5, sA: 0.6875, eA: 0.8125)
            case 4: return Electrode.path(size: size, eR: 3 / 5.5, sR: 1 / 5.5, sA: 0.1875, eA: 0.3125)
            default: return nil
            }
        case .mastoid:
            switch suffix {
            case 1: return Electrode.path(size: size, eR: 5.5 / 5.5, sR: 5 / 5.5, sA: 0.7, eA: 0.8)
            case 2: return Electrode.path(size: size, eR: 5.5 / 5.5, sR: 5 / 5.5, sA: 0.2, eA: 0.3)
            default: return nil
            }
        }
    }
    
    // MARK: STATIC FUNCTIONS
    /// Calculates the path for a sector in a given domain and range.
    /// - Parameters:
    ///   - size: The domain and range of the sector.
    ///   - eR: The ending radius.
    ///   - sR: The starting radius.
    ///   - sA: The starting angle.
    ///   - eA: The ending angle.
    /// - Returns: A path for a sector in the given domain and range.
    static func path(size: CGSize, eR: Double, sR: Double, sA: Double, eA: Double) -> Path {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = min(size.height, size.width) / 2
        
        let sAR = Angle(radians: ((2 - (sA * 2)) * Double.pi) - (Double.pi * 0.5))
        let eAR = Angle(radians: ((2 - (eA * 2)) * Double.pi) - (Double.pi * 0.5))
        
        var path = Path()
        
        path.addArc(center: center, radius: maxRadius * eR, startAngle: sAR, endAngle: eAR, clockwise: true)
        path.addLine(to: Electrode.Polar(radius: sR, angle: eA).cgPoint(in: size))
        path.addArc(center: center, radius: maxRadius * sR, startAngle: eAR, endAngle: sAR, clockwise: false)
        path.addLine(to: Electrode.Polar(radius: eR, angle: sA).cgPoint(in: size))
        
        return path
    }
    
    static var rings: [Double] = [(2 / 5.5), (4 / 5.5)]
    
    // MARK: STRUCTURES
    /// A polar coordinate system for electrodes.
    struct Polar {
        /// The radius/magnitude of the vector, ranging from `0` to `1`.
        var radius: Double
        /// The angle of the vector.
        var angle: Angle
        
        /// Initialises a polar coordinate instance.
        /// - Parameters:
        ///   - radius: Value from 0 to 1 describing the length of the vector.
        ///   - angle: Value from 0 to 1 describing the proportion of the way round a circle.
        init(radius: Double, angle: Double) {
            self.radius = radius
            self.angle = Angle(radians: 2 * Double.pi * angle)
        }
        
        /// Finds the cartesian coordinate in a given a domain and range.
        /// - Parameter size: The domain and range of the cartesian plane.
        /// - Returns: The cartesian coordinates.
        func cgPoint(in size: CGSize) -> CGPoint {
            let maxRadius = min(size.height, size.width) / 2
            
            let commonFactor = -1 * maxRadius * radius
            
            let x = (size.width / 2) + commonFactor * sin(angle.radians)
            let y = (size.height / 2) + commonFactor * cos(angle.radians)
            
            return CGPoint(x: x, y: y)
        }
    }
    
    // MARK: ENUMERATIONS
    /// An enumeration for all the lobes/areas of the brain and is more specific than ``GeneralArea-swift.enum``.
    enum Prefix: String, Codable, CaseIterable, Identifiable {
        var id: Self { self }
        
        case prefrontal, frontal, temporal, parietal, occipital, central, mastoid
        
        /// The symbol for each lobe/area.
        var symbol: String {
            switch self {
            case .prefrontal: return "Fp"
            case .frontal: return "F"
            case .temporal: return "T"
            case .parietal: return "P"
            case .occipital: return "O"
            case .central: return "C"
            case .mastoid: return "A"
            }
        }
    }
    /// Describes the general areas of the scalp.
    enum GeneralArea: String {
        case left, central, right
    }
}
