//
//  RootView.swift
//  Trace
//
//  Created by Tahmid Azam on 24/12/2022.
//

import SwiftUI
import Charts

struct RootView: View {
    @Binding var doc: TraceDocument
    @State var detail: Detail = .plot
    @State var showRightSidebar: Bool = true
    
    @State var sheetPresented: RootViewSheet? = nil
    @StateObject var plottingState = PlottingState()
    
    // MARK: ENUMERATIONS
    enum Detail: String, CaseIterable {
        case plot, streams, events
    }
    enum RootViewSheet: Identifiable {
        var id: Self { self }
        
        case events, study
        
#if os(iOS)
        case detail
#endif
    }
    
    var potentialRange: ClosedRange<Double> {
        doc.contents.potentialRange ?? 0...0
    }
    var timeRange: ClosedRange<Double> {
        return doc.contents.time(at: sampleRange.lowerBound)...doc.contents.time(at: sampleRange.upperBound)
    }
    var sampleRange: ClosedRange<Int> {
        return (plottingState.windowStartIndex...(plottingState.windowStartIndex + plottingState.windowSize - 1))
    }
    
    
    var body: some View {
        if doc.contents.streams.isEmpty {
            OnboardingView(doc: $doc)
        } else {
            document
                .task {
                    plottingState.selectedStreams = doc.contents.streams
                    plottingState.selectedEventTypes = doc.contents.eventTypes
                }
                .onChange(of: plottingState.selectedStreams) { newValue in
                    plottingState.selectedStreams = newValue.sorted(by: { lhs, rhs in
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
#if os(iOS)
                    case .detail:
                        NavigationStack {
                            VStack(spacing: 0.0) {
                                HStack {
                                    Picker("", selection: $detail) {
                                        ForEach(Detail.allCases, id: \.self) { detail in
                                            Text(detail.rawValue.capitalized).tag(detail)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.segmented)
                                    .padding(.vertical, 8)
                                    .padding(.trailing)
                                    
                                    Button {
                                        sheetPresented = nil
                                    } label: {
                                        Label("Close", systemImage: "xmark.circle.fill")
                                            .labelStyle(.iconOnly)
                                            .font(.title)
                                    }
                                    .symbolRenderingMode(.hierarchical)
                                }
                                .padding(.horizontal)
                                
                                Divider()
                                
                                switch detail {
                                case .plot:
                                    PlotDetailView(
                                        doc: $doc, plottingState: plottingState)
                                case .streams:
                                    StreamsDetailView(
                                        doc: $doc, plottingState: plottingState)
                                case .events:
                                    EventsDetailView(
                                        doc: $doc, plottingState: plottingState)
                                }
                            }
                        }
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.hidden)
#endif
                    }
                }
        }
    }
#if os(macOS)
    var document: some View {
        HStack(spacing: 0.0) {
            Group {
                switch plottingState.visualisation {
                case .stackedPlot:
                    StackedPlotView(doc: $doc, plottingState: plottingState, potentialRange: potentialRange, timeRange: timeRange, sampleRange: sampleRange)
                case .scalpMap:
                    ScalpMapVisualisationView(doc: $doc, plottingState: plottingState)
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
                                doc: $doc, plottingState: plottingState)
                        case .streams:
                            StreamsDetailView(
                                doc: $doc, plottingState: plottingState)
                        case .events:
                            EventsDetailView(
                                doc: $doc, plottingState: plottingState)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(width: PlottingState.rightSidebarWidth)
                .transition(.move(edge: .trailing))
            }
        }
        .frame(minWidth: PlottingState.minWindowWidth, minHeight: PlottingState.minWindowHeight)
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
    }
#elseif os(iOS)
    var document: some View {
        Group {
            HStack(spacing: 0.0) {
                Divider()
                
                switch plottingState.visualisation {
                case .stackedPlot:
                    StackedPlotView(doc: $doc, plottingState: plottingState, potentialRange: potentialRange, timeRange: timeRange, sampleRange: sampleRange)
                case .scalpMap:
                    ScalpMapVisualisationView(doc: $doc, plottingState: plottingState)
                }
                
                Divider()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    sheetPresented = .detail
                } label: {
                    Label("Format", systemImage: "paintbrush")
                }
            }
        }
    }
#else
    var document: some View {
        EmptyView()
    }
#endif
}
