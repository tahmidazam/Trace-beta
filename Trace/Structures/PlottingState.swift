//
//  PlottingState.swift
//  Trace
//
//  Created by Tahmid Azam on 30/12/2022.
//

import Foundation
import SwiftUI

class PlottingState: ObservableObject {
    @Published var selectedStreams: [Stream] = []
    @Published var selectedEventTypes: [String] = []
    
    @Published var visualisation: Visualisation = .stackedPlot
        
    @Published var windowSize: Int = 1000
    @Published var windowStartIndex: Int = 0
    @Published var stepSize: Int = 1
    @Published var pointsPerCGPoint: Int = 1
    @Published var sampleIndex: Int = 0
    @State var marker: Int? = nil
    
    @Published var showEpochs: Bool = true
    @Published var epochFillOpacity: CGFloat = 0.025
    @Published var colorLinePlot: Bool = true
    @Published var showElectrodeLabels: Bool = true
    @Published var showElectrodePotentials: Bool = true
    @Published var lineWidth: CGFloat = 1.0
    
    @Published var visiblePotentialRange: ClosedRange<Double> = 0...0

    #if os(macOS)
    @State var mouseLocation: NSPoint? = nil
    #endif
    
    static let minWindowWidth: CGFloat = 600
    static let minWindowHeight: CGFloat = 400
    static let rightSidebarWidth: CGFloat = 300
    static let verticalPaddingProportion: CGFloat = 0.0
    
    // MARK: ENUMERATIONS
    enum Visualisation { case stackedPlot, scalpMap }
}
