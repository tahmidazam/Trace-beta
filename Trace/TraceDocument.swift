//
//  TraceDocument.swift
//  Trace
//
//  Created by Tahmid Azam on 05/07/2022.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var trace: UTType {
        UTType(importedAs: "com.example.trace")
    }
}

/// The trace document structure.
struct TraceDocument: FileDocument {
    /// The content types the trace document can read.
    static var readableContentTypes: [UTType] { [.trace] }
    
    /// The contents of the trace document.
    var contents: TraceDocumentContents
    
    /// Initialises a trace document.
    /// - Parameter trace: the trace stored in the document.
    init(trace: TraceDocumentContents = TraceDocumentContents(streams: [], sampleRate: 200)) {
        self.contents = trace
    }
    
    /// Initialises a trace document by reading a file and decoding its JSON data.
    /// - Parameter configuration: The configuration for reading the trace document.
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        contents = try JSONDecoder().decode(TraceDocumentContents.self, from: data)
    }
    
    /// Wraps the trace document structure to a file.
    /// - Parameter configuration: The configuration for writing the trace document.
    /// - Returns: A file wrapper of the trace document's data.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(contents)
        return .init(regularFileWithContents: data)
    }
}

/// The data structure for the contents of a trace document.
struct TraceDocumentContents: Identifiable, Codable {
    var id = UUID()
    
    /// The name of the subject the electroencephalographic data was sourced from.
    var subject: String?
    /// Information relating to the subject.
    var info: String?
    
    /// An array containing the streams of EEG data for each electrode in the trace.
    var streams: [Stream]
    /// The sample rate of the EEG data, measured in Hertz, Hz.
    var sampleRate: Double
    /// A dictionary containing each event type their events as indexes.
    var events: [String: [Int]]?
    
    /// The number of samples.
    var sampleCount: Int? {
        if let first = streams.first {
            return first.samples.count
        } else {
            return nil
        }
    }
    /// The number of samples as text, formatted with a unit and alterations for plurals.
    var formattedSampleCount: String? {
        if let count = sampleCount {
            return "\(count) sample\(count == 1 ? "" : "s")"
        } else {
            return nil
        }
    }
    /// Duration of the recording in seconds.
    var duration: Double? {
        if let count = sampleCount {
            return Double(count) * Double(1 / sampleRate)
        } else {
            return nil
        }
        
    }
    
    var maxPotential: Double? {
        return streams.map { stream in
            return stream.samples
        }.flatMap({ (element: [Double]) -> [Double] in
            return element
        })
        .max()
    }
    
    var minPotential: Double? {
        return streams.map { stream in
            return stream.samples
        }.flatMap({ (element: [Double]) -> [Double] in
            return element
        })
        .min()
    }
    
    /// Converts a stream index to a time value, in seconds, s.
    /// - Parameter index: The index to convert.
    /// - Returns: The time value, in seconds, s.
    func time(at index: Int) -> Double {
        return Double(index) * (1 / sampleRate)
    }
    /// Imports (multiple) streams from a `.csv` file.
    ///
    /// Each column from the `.csv` file corresponds to a singular stream. The header of each column (i.e., the first row), is used to identify the electrode involved in the stream. The rest of the rows are used to extract the samples for each stream.
    ///
    /// The import will fail in the following cases:
    ///  - The electrode symbol cannot be interpreted into an electrode instance.
    ///  - The number format for any one of the samples is incorrect (i.e., the `String` cannot be transformed into a `Double`).
    ///
    /// - Parameter csv: The raw text from the csv file.
    /// - Returns: Stream instances from the csv file.
    static func streams(from csv: String) -> [Stream]? {
        var streams: [Stream] = []
        
        var lines = csv.components(separatedBy: .newlines).filter { $0 != "" }
        
        let headerLine = lines.remove(at: 0)
        
        let electrodeSymbols = headerLine.components(separatedBy: ",").map { string in
            string.trimmingCharacters(in: .whitespacesAndNewlines )
        }
        
        for symbolIndex in electrodeSymbols.indices {
            guard let electrode = Electrode.electrode(from: electrodeSymbols[symbolIndex]) else { return nil }
            
            var streamDataPoints: [Double] = []
            
            for line in lines {
                let lineDataPoints = line.components(separatedBy: ",")
                
                let dataPoint = lineDataPoints[symbolIndex].filter { $0.isNumber || $0 == "." || $0 == "-"}
                
                guard let dataPoint = Double(dataPoint) else { return nil }
                
                streamDataPoints.append(dataPoint)
            }
            
            let stream = Stream(electrode: electrode, samples: streamDataPoints)
            
            streams.append(stream)
        }
        
        return streams
    }
    
    /// A data structure suitable for parsing by charts that represents a potential, along with its timestamp and associated electrode.
    struct SampleDataPoint: Hashable {
        static func == (lhs: TraceDocumentContents.SampleDataPoint, rhs: TraceDocumentContents.SampleDataPoint) -> Bool {
            lhs.electrode == rhs.electrode && lhs.timestamp == rhs.timestamp && lhs.potential == rhs.potential
        }
        
        /// The electrode associated with the data point.
        var electrode: Electrode
        /// The x-axis time value in seconds, s.
        var timestamp: Double
        /// The y-axis potential value in millivolts, mV.
        var potential: Double
    }
    
    /// Converts a stream to a chart-parsable data structure.
    /// - Parameters:
    ///   - stream: The stream to map.
    ///   - sampleRate: The sample rate of the stream.
    /// - Returns: A chart-parsable stream.
    static func sampleDataPoints(from streams: [Stream], sampleRate: Double, spliced: ClosedRange<Int>? = nil) -> [TraceDocumentContents.SampleDataPoint] {
        var data: [TraceDocumentContents.SampleDataPoint] = []
        
        for stream in streams {
            if spliced != nil {
                for sampleIndex in spliced!.lowerBound..<min(stream.samples.count, spliced!.upperBound) {
                    let dataPoint = TraceDocumentContents.SampleDataPoint(
                        electrode: stream.electrode,
                        timestamp: (1 / sampleRate) * Double(sampleIndex),
                        potential: stream.samples[sampleIndex]
                    )
                    
                    data.append(dataPoint)
                }
            } else {
                for sampleIndex in 0..<stream.samples.count {
                    let dataPoint = TraceDocumentContents.SampleDataPoint(
                        electrode: stream.electrode,
                        timestamp: (1 / sampleRate) * Double(sampleIndex),
                        potential: stream.samples[sampleIndex]
                    )
                    
                    data.append(dataPoint)
                }
            }
        }
        
        return data
    }
}

/// The data structure of an electrode's data stream.
struct Stream: Identifiable, Codable, Hashable {
    var id = UUID()
    
    /// The electrode associated with the potential samples.
    var electrode: Electrode
    /// Array holding the potentials at each time step.
    var samples: [Double]
    
    /// A data structure suitable for parsing by charts.
    struct SampleDataPoint: Hashable {
        /// The x-axis time value.
        var timestamp: Double
        /// The y-axis potential value.
        var potential: Double
    }
    
    var maxPotential: Double? {
        samples.max()
    }
    var minPotential: Double? {
        samples.min()
    }
    
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
    static func sampleDataPoints(from samples: [Double], sampleRate: Double) -> [Stream.SampleDataPoint] {
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
    
    static func scalpMapColor(value: Double, min: Double, max: Double) -> Color {
        
        let positiveColors: [UIColor] = [UIColor(.green), UIColor(.yellow), UIColor(.red)]
        let negativeColors: [UIColor] = [UIColor(.green), UIColor(.cyan), UIColor(.blue)]
        
        if value >= 0 {
            let prop: Double = (value / max) * 100
            
            return Color(uiColor: positiveColors.intermediate(percentage: prop))
        } else {
            let prop: Double = (value / min) * 100
            
            return Color(uiColor: negativeColors.intermediate(percentage: prop))
        }
    }
}

/// The data structure for identifying an electrode.
struct Electrode: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    
    /// The lobe/area of the brain associated with the electrode position.
    var prefix: Prefix
    /// The index associated with the electrode position, with a range from 0 to 8 inclusive.
    var suffix: Int
    
    /// An enumeration for all the lobes/areas of the brain.
    enum Prefix: String, Codable, CaseIterable {
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
    
    /// The symbol of the electrode.
    ///
    /// Each symbol has two components, the prefix and suffix. The suffix is the last letter, and is either "z" for 0, or a number. The rest of the symbol is the prefix, and is a shorthand symbol for the lobe/area corresponding to the electrode placement on scalp.
    /// 
    var symbol: String {
        "\(self.prefix.symbol)\(self.suffix == 0 ? "z" : "\(self.suffix)")"
    }
    /// A prose description of the location of the electrode on the scalp, including the side of the brain, as well as the lobe/area.
    var locationDescription: String {
        "\(self.suffix.side) \(self.prefix.rawValue)"
    }
    
    /// Turns an electrode symbol into an electrode instance.
    ///
    /// The function will return nil if the symbol does not correspond to electrode labelling convention.
    ///
    /// - Parameter symbol: The symbol of the electrode.
    /// - Returns: An electrode instance.
    static func electrode(from symbol: String) -> Electrode? {
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
        
        return Electrode(prefix: prefix, suffix: suffix)
    }
    
    struct Polar {
        var radius: Double
        var angle: Double
        
        func cgPoint(in size: CGSize) -> CGPoint {
            let maxRadius = min(size.height, size.width) / 2
            
            let x = (size.width / 2) + -1 * maxRadius * self.radius * __sinpi(self.angle * 2)
            let y = (size.height / 2) + -1 * maxRadius * self.radius * __cospi(self.angle * 2)
            
            return CGPoint(x: x, y: y)
        }
    }
    
    /// Finds the polar coordinates of the electrode location on the scalp.
    ///
    /// Will return `nil` if the location is not supported by Trace.
    /// 
    /// - Parameter electrode: The electrode to find.
    /// - Returns: The location of the electrode on the scalp, in polar coordinate form (i.e., a radius and an angle, with north being `0` degrees/radians).
    static func location(from electrode: Electrode) -> Polar? {
        switch electrode.prefix {
        case .prefrontal:
            switch electrode.suffix {
            case 1: return Polar(radius: 4 / 7, angle: 0.05)
            case 2: return Polar(radius: 4 / 7, angle: 0.95)
            default: return nil
            }
        case .frontal:
            switch electrode.suffix {
            case 0: return Polar(radius: 2 / 7, angle: 0.0)
            case 3: return Polar(radius: 2 / 7, angle: 0.875)
            case 4: return Polar(radius: 2 / 7, angle: 0.125)
            case 7: return Polar(radius: 4 / 7, angle: 0.85)
            case 8: return Polar(radius: 4 / 7, angle: 0.15)
            default: return nil
            }
        case .temporal:
            switch electrode.suffix {
            case 3: return Polar(radius: 4 / 7, angle: 0.75)
            case 4: return Polar(radius: 4 / 7, angle: 0.25)
            case 5: return Polar(radius: 4 / 7, angle: 0.65)
            case 6: return Polar(radius: 4 / 7, angle: 0.35)
            default: return nil
            }
        case .parietal:
            switch electrode.suffix {
            case 0: return Polar(radius: 2 / 7, angle: 0.5)
            case 3: return Polar(radius: 2 / 7, angle: 0.625)
            case 4: return Polar(radius: 2 / 7, angle: 0.375)
            default: return nil
            }
        case .occipital:
            switch electrode.suffix {
            case 1: return Polar(radius: 4 / 7, angle: 0.45)
            case 2: return Polar(radius: 4 / 7, angle: 0.55)
            default: return nil
            }
        case .central:
            switch electrode.suffix {
            case 0: return Polar(radius: 0 / 7, angle: 0.0)
            case 3: return Polar(radius: 2 / 7, angle: 0.75)
            case 4: return Polar(radius: 2 / 7, angle: 0.25)
            default: return nil
            }
        case .mastoid:
            switch electrode.suffix {
            case 1: return Polar(radius: 6 / 7, angle: 0.75)
            case 2: return Polar(radius: 6 / 7, angle: 0.25)
            default: return nil
            }
        }
    }
    
    static func path(size: CGSize, lR: Double, sR: Double, sA: Double, eA: Double) -> Path {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = min(size.height, size.width) / 2
        
        let sAR = Angle(radians: ((2 - (sA * 2)) * Double.pi) - (Double.pi * 0.5))
        let eAR = Angle(radians: ((2 - (eA * 2)) * Double.pi) - (Double.pi * 0.5))
        
        var path = Path()
        
        path.addArc(center: center, radius: maxRadius * lR, startAngle: sAR, endAngle: eAR, clockwise: true)
        path.addLine(to: Electrode.Polar(radius: sR, angle: eA).cgPoint(in: size))
        path.addArc(center: center, radius: maxRadius * sR, startAngle: eAR, endAngle: sAR, clockwise: false)
        path.addLine(to: Electrode.Polar(radius: lR, angle: sA).cgPoint(in: size))
        
        return path
    }
    
    static func sector(stream: Stream, size: CGSize) -> Path? {
        switch stream.electrode.prefix {
        case .prefrontal:
            switch stream.electrode.suffix {
            case 1: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0, eA: 0.1)
            case 2: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0.9, eA: 0)
            default: return nil
            }
        case .frontal:
            switch stream.electrode.suffix {
            case 0: return path(size: size, lR: 3 / 7, sR: 1 / 7, sA: 0.9375, eA: 0.0625)
            case 3: return path(size: size, lR: 3 / 7, sR: 1 / 7, sA: 0.0625, eA: 0.1875)
            case 4: return path(size: size, lR: 3 / 7, sR: 1 / 7, sA: 0.8125, eA: 0.9375)
            case 7: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0.8, eA: 0.9)
            case 8: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0.1, eA: 0.2)
            default: return nil
            }
        case .temporal:
            switch stream.electrode.suffix {
            case 3: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0.7, eA: 0.8)
            case 4: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0.2, eA: 0.3)
            case 5: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0.6, eA: 0.7)
            case 6: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0.3, eA: 0.4)
            default: return nil
            }
        case .parietal:
            switch stream.electrode.suffix {
            case 0: return path(size: size, lR: 3 / 7, sR: 1 / 7, sA: 0.4375, eA: 0.5625)
            case 3: return path(size: size, lR: 3 / 7, sR: 1 / 7, sA: 0.5625, eA: 0.6875)
            case 4: return path(size: size, lR: 3 / 7, sR: 1 / 7, sA: 0.3125, eA: 0.4375)
            default: return nil
            }
        case .occipital:
            switch stream.electrode.suffix {
            case 1: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0.4, eA: 0.5)
            case 2: return path(size: size, lR: 5 / 7, sR: 3 / 7, sA: 0.5, eA: 0.6)
            default: return nil
            }
        case .central:
            switch stream.electrode.suffix {
            case 0:
                let r = min(size.height, size.width) * (1 / 7)
                return Path.init(ellipseIn: CGRect(x: (size.width / 2) - (r / 2), y: (size.height / 2)  - (r / 2), width: r, height: r))
            case 3: return path(size: size, lR: 3 / 7, sR: 1 / 7, sA: 0.6875, eA: 0.8125)
            case 4: return path(size: size, lR: 3 / 7, sR: 1 / 7, sA: 0.1875, eA: 0.3125)
            default: return nil
            }
        case .mastoid:
            switch stream.electrode.suffix {
            case 1: return path(size: size, lR: 7 / 7, sR: 5 / 7, sA: 0.725, eA: 0.775)
            case 2: return path(size: size, lR: 7 / 7, sR: 5 / 7, sA: 0.225, eA: 0.275)
            default: return nil
            }
        }
    }
}

extension Int {
    var side: String {
        if self == 0 {
            return "central"
        } else if self.quotientAndRemainder(dividingBy: 2).remainder == 1 {
            return "left"
        } else {
            return "right"
        }
    }
}

extension Array where Element: UIColor {
    func intermediate(percentage: CGFloat) -> UIColor {
        let percentage = Swift.max(Swift.min(percentage, 100), 0) / 100
        switch percentage {
        case 0: return first ?? .clear
        case 1: return last ?? .clear
        default:
            let approxIndex = percentage / (1 / CGFloat(count - 1))
            let firstIndex = Int(approxIndex.rounded(.down))
            let secondIndex = Int(approxIndex.rounded(.up))
            let fallbackIndex = Int(approxIndex.rounded())
            
            let firstColor = self[firstIndex]
            let secondColor = self[secondIndex]
            let fallbackColor = self[fallbackIndex]
            
            var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            guard firstColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return fallbackColor }
            guard secondColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return fallbackColor }
            
            let intermediatePercentage = approxIndex - CGFloat(firstIndex)
            return UIColor(
                red: CGFloat(r1 + (r2 - r1) * intermediatePercentage),
                green: CGFloat(g1 + (g2 - g1) * intermediatePercentage),
                blue: CGFloat(b1 + (b2 - b1) * intermediatePercentage),
                alpha: CGFloat(a1 + (a2 - a1) * intermediatePercentage)
            )
        }
    }
}

extension CGPoint {
    func distance(to: CGPoint) -> CGFloat {
        return sqrt((self.x - to.x) * (self.x - to.x) + (self.y - to.y) * (self.y - to.y))
    }
}

extension Double {
    func format() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.usesGroupingSeparator = false
        
        let number = NSNumber(value: self)
        let formattedValue = formatter.string(from: number)!
        return formattedValue
    }
}
