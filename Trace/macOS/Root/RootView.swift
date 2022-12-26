//
//  RootView.swift
//  Trace
//
//  Created by Tahmid Azam on 24/12/2022.
//

import SwiftUI
import Charts

#if os(macOS)
struct RootView: View {
    @Binding var doc: TraceDocument
    
    @State private var showRightSidebar: Bool = true
    @State private var selectedStreams: [Stream] = []
    @State private var visualisation: Visualisation = .stackedPlot
    @State private var detail: Detail = .plot
    
    @State var plottingWindowSampleSize = 50
    @State var plottingWindowFirstSampleIndex = 0
    @State var scalpMapSampleIndexToDisplay: Int = 0
    
    @State var hoveringOver: Stream.ID? = nil
    
    @State var selectedEventTypes: [String] = []
    @State var showEpochs: Bool = true
    
    @State var showElectrodeLabels: Bool = true
    @State var showElectrodePotentials: Bool = true
    
    @State var sheetPresented: RootViewSheet? = nil
    
    @State var mouseLocation: NSPoint? = nil
    
    @State var lineWidth: CGFloat = 1.0
    
    @State var marker: Int? = nil
    
    private let minWindowWidth: CGFloat = 600
    private let minWindowHeight: CGFloat = 400
    private let rightSidebarWidth: CGFloat = 300
    private let verticalPaddingProportion: CGFloat = 0.1
    
    
    
    // MARK: ENUMERATIONS
    
    enum Visualisation {
        case stackedPlot, scalpMap
    }
    enum Detail: String, CaseIterable {
        case plot, streams, events
    }
    enum RootViewSheet: Identifiable {
        var id: Self { self }
        
        case events, study
    }
    
    var potentialRange: ClosedRange<Double> {
        doc.contents.potentialRange ?? 0...0
    }
    var timeRange: ClosedRange<Double> {
        return doc.contents.time(at: sampleRange.lowerBound)...doc.contents.time(at: sampleRange.upperBound)
    }
    var sampleRange: ClosedRange<Int> {
        return (plottingWindowFirstSampleIndex...(plottingWindowFirstSampleIndex + plottingWindowSampleSize - 1))
    }
    
    var body: some View {
        if doc.contents.streams.isEmpty {
            OnboardingView(doc: $doc)
        } else {
            document
        }
    }
    
    var document: some View {
        HStack(spacing: 0.0) {
            Group {
                switch visualisation {
                case .stackedPlot:
                    StackedPlotView(
                        doc: $doc,
                        selectedEventTypes: $selectedEventTypes,
                        plottingWindowFirstSampleIndex: $plottingWindowFirstSampleIndex,
                        plottingWindowSampleSize: $plottingWindowSampleSize,
                        showEpochs: $showEpochs, visualisation: $visualisation,
                        scalpMapSampleIndexToDisplay: $scalpMapSampleIndexToDisplay,
                        selectedStreams: $selectedStreams,
                        verticalPaddingProportion: verticalPaddingProportion,
                        potentialRange: potentialRange,
                        timeRange: timeRange,
                        sampleRange: sampleRange,
                        mouseLocation: $mouseLocation,
                        lineWidth: $lineWidth,
                        marker: $marker
                    )
                case .scalpMap:
                    ScalpMapVisualisationView(
                        doc: $doc,
                        selectedStreams: $selectedStreams,
                        scalpMapSampleIndexToDisplay: $scalpMapSampleIndexToDisplay,
                        showElectrodeLabels: $showElectrodeLabels,
                        showElectrodePotentials: $showElectrodePotentials,
                        showEpochs: $showEpochs,
                        selectedEventTypes: $selectedEventTypes
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if showRightSidebar {
                HStack(spacing: 0.0) {
                    Divider()
                    
                    VStack(spacing: 0.0) {
                        DetailPickerView(doc: $doc, detail: $detail)
                        
                        Divider()
                        
                        switch detail {
                        case .plot:
                            PlotDetailView(
                                doc: $doc,
                                visualisation: $visualisation,
                                plottingWindowSampleSize: $plottingWindowSampleSize,
                                showElectrodeLabels: $showElectrodeLabels,
                                showElectrodePotentials: $showElectrodePotentials,
                                lineWidth: $lineWidth
                            )
                        case .streams:
                            StreamsDetailView(
                                doc: $doc,
                                selectedStreams: $selectedStreams
                            )
                        case .events:
                            EventsDetailView(
                                doc: $doc,
                                selectedEventTypes: $selectedEventTypes,
                                showEpochs: $showEpochs
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(width: rightSidebarWidth)
                .transition(.move(edge: .trailing))
            }
        }
        .frame(minWidth: minWindowWidth, minHeight: minWindowHeight)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    sheetPresented = .study
                } label: {
                    Label("Edit study details...", systemImage: "person")
                }
                
                Button {
                    sheetPresented = .events
                } label: {
                    Label("Edit events...", systemImage: "square.stack.3d.down.right")
                }
                
                Button {
                    withAnimation {
                        showRightSidebar.toggle()
                    }
                } label: {
                    Label("Show right sidebar", systemImage: "sidebar.right")
                }
            }
        }
        .task {
            selectedStreams = doc.contents.streams
            selectedEventTypes = doc.contents.eventTypes
        }
        .onChange(of: selectedStreams) { newValue in
            selectedStreams = newValue.sorted(by: { lhs, rhs in
                if lhs.electrode.prefix == rhs.electrode.prefix {
                    return lhs.electrode.suffix < rhs.electrode.suffix
                }
                
                return lhs.electrode.prefix.rawValue < rhs.electrode.prefix.rawValue
            })
        }
        .sheet(item: $sheetPresented) { sheet in
            switch sheet {
            case .events:
                EventsView(doc: $doc)
                    .frame(minWidth: 500, minHeight: 400)
            case .study: StudyView(doc: $doc)
                    .frame(minWidth: 500, minHeight: 400)
            }
        }
    }
    
    func rowHeight(size: CGSize) -> CGFloat {
        return Double(size.height * (1 - verticalPaddingProportion)) / Double(selectedStreams.count)
    }
}
#endif
