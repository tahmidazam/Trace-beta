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
    
    @Published var visualiation: Visualisation = .stackedPlot
        
    @Published var windowSize: Int = 50
    @Published var windowStartIndex: Int = 0
    @Published var sampleIndex: Int = 0
    @State var marker: Int? = nil
    
    @Published var showEpochs: Bool = true
    @Published var showElectrodeLabels: Bool = true
    @Published var showElectrodePotentials: Bool = true
    @State var lineWidth: CGFloat = 1.0

    #if os(macOS)
    @State var mouseLocation: NSPoint? = nil
    #endif
    
    static let minWindowWidth: CGFloat = 600
    static let minWindowHeight: CGFloat = 400
    static let rightSidebarWidth: CGFloat = 300
    static let verticalPaddingProportion: CGFloat = 0.1
    
    // MARK: ENUMERATIONS
    enum Visualisation { case stackedPlot, scalpMap }
}
