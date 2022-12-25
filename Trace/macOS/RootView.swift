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
    @State var showCSVFileImporter: Bool = false
    @State var alert: StreamsViewAlert? = nil
    
    private let minWindowWidth: CGFloat = 600
    private let minWindowHeight: CGFloat = 400
    private let rightSidebarWidth: CGFloat = 300
    private let verticalPaddingProportion: CGFloat = 0.1
    
    // MARK: ENUMERATIONS
    
    enum Visualisation {
        case stackedPlot, scalpMap
    }
    enum Detail {
        case plot, streams, events
    }
    enum RootViewSheet: Identifiable {
        var id: Self { self }
        
        case events, study
    }
    enum StreamsViewAlert: Identifiable {
        var id: UUID { UUID() }
        
        case fileImportFailure
        case csvFormatInvalid
        
        var alert: Alert {
            switch self {
            case .fileImportFailure: return Alert(title: Text("An error occured."), message: Text("Failed to import file."))
            case .csvFormatInvalid:
                return Alert(title: Text("An error occured."), message: Text("The CSV format is invalid."))
            }
        }
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
            onboarding
        } else {
            document
        }
    }
    
    var onboarding: some View {
        VStack {
            Text("Get started by importing EEG data into your Trace project")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title3.bold())
                .multilineTextAlignment(.leading)
            
            Text("Import multi-stream data from \(Image(systemName: "rectangle.split.3x3")) CSV, or stream-by-stream from pasted \(Image(systemName: "text.alignleft")) text.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .padding(.vertical)
            
            Text("In CSV files, each column represents a stream, with the first cell corresponding to the electrode label, and the rest of the cells form the array of samples. Each column (i.e., each stream) must have the same number of samples, and the electrode label must satisfy the format specified above.\n\nPasted text must be newline-separated values, and electrode information is inputted separately.\n\nInformation about import file requirements, electrode support and general support can be found on the [GitHub page](https://github.com/tahmidazam/Trace).")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            addFromCSVButton
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top)
        }
        .frame(maxWidth: 400)
        .padding()
        .fileImporter(isPresented: $showCSVFileImporter, allowedContentTypes: [.commaSeparatedText, .text], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                processFile(urls: urls)
            case .failure(_):
                alert = .fileImportFailure
            }
        }
        .alert(item: $alert, content: { alert in alert.alert })
    }
    var addFromCSVButton: some View {
        Button {
            showCSVFileImporter.toggle()
        } label: {
            Label("Import from CSV", systemImage: "rectangle.split.3x3")
                .frame(maxWidth: .infinity)
        }
    }
    
    var document: some View {
        HStack(spacing: 0.0) {
            Group {
                switch visualisation {
                case .stackedPlot: stackedPlot
                case .scalpMap: scalpMap
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if showRightSidebar {
                HStack(spacing: 0.0) {
                    Divider()
                    
                    VStack(spacing: 0.0) {
                        detailPicker
                        
                        Divider()
                        
                        switch detail {
                        case .plot: plotDetail
                        case .streams: streamsDetail
                        case .events: eventsDetail
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
    
    var detailPicker: some View {
        HStack(spacing: 0.0) {
            Button {
                detail = .plot
            } label: {
                if detail == .plot {
                    Text("Plot")
                        .foregroundColor(.white)
                        .padding(2)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 5.0).foregroundColor(.accentColor))
                } else {
                    Text("Plot")
                        .padding(2)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 5.0).foregroundColor(.clear))
                }
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity)
            .padding(.trailing, 4)
            
            Button {
                detail = .streams
            } label: {
                if detail == .streams {
                    Text("Streams")
                        .foregroundColor(.white)
                        .padding(2)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 5.0).foregroundColor(.accentColor))
                } else {
                    Text("Streams")
                        .padding(2)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 5.0).foregroundColor(.clear))
                }
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity)
            .padding(.trailing, 4)
            
            Button {
                detail = .events
            } label: {
                if detail == .events {
                    Text("Events")
                        .foregroundColor(.white)
                        .padding(2)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 5.0).foregroundColor(.accentColor))
                } else {
                    Text("Events")
                        .padding(2)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 5.0).foregroundColor(.clear))
                }
            }
            .buttonStyle(.borderless)
            
        }
        .padding(4)
    }
    var streamsDetail: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0.0) {
                LabeledContent {
                    EmptyView()
                } label: {
                    Text("Streams")
                    Text("Select the streams to plot.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
                
                ForEach(Electrode.Prefix.allCases) { electrodePrefix in
                    let filteredStreams = doc.contents.streams.filter({ $0.electrode.prefix == electrodePrefix })
                    
                    DisclosureGroup {
                        VStack {
                            ForEach(filteredStreams) { stream in
                                HStack {
                                    Button {
                                        if selectedStreams.contains(stream) {
                                            selectedStreams.removeAll { stream_ in
                                                stream_.id == stream.id
                                            }
                                        } else {
                                            selectedStreams.append(stream)
                                        }
                                    } label: {
                                        if selectedStreams.contains(stream) {
                                            Image(systemName: "circle.inset.filled")
                                                .foregroundColor(.accentColor)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                    .padding(.trailing)
                                    
                                    Text(stream.electrode.symbol)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    } label: {
                        LabeledContent {
                            Text("\(filteredStreams.count)")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } label: {
                            Text(electrodePrefix.rawValue.capitalized)
                        }
                    }
                }
                
                HStack {
                    Button("Deselect all") {
                        selectedStreams = []
                    }
                    
                    Button("Select all") {
                        selectedStreams = doc.contents.streams
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                
                Divider()
            }
            .padding()
        }
    }
    var plotDetail: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0.0) {
                LabeledContent {
                    Picker("", selection: $visualisation) {
                        Label("Stacked plot", systemImage: "chart.bar.doc.horizontal")
                            .tag(Visualisation.stackedPlot)
                        
                        Label("Scalp map", systemImage: "circle.dashed")
                            .tag(Visualisation.scalpMap)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .buttonStyle(.borderless)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } label: {
                    Text("Plot type")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom)
                
                Divider()
                
                switch visualisation {
                case .stackedPlot:
                    LabeledContent {
                        Stepper("\(plottingWindowSampleSize)", value: $plottingWindowSampleSize, in: 50...500, step: 50)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } label: {
                        Text("Plotting window size")
                        Text("The number of samples plotted")
                    }
                    .padding(.vertical)
                    
                    Divider()
                case .scalpMap:
                    VStack {
                        Toggle(isOn: $showElectrodeLabels) {
                            Text("Show electrode labels")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $showElectrodePotentials) {
                            Text("Show electrode potentials")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical)
                    
                    Divider()
                }
            }
            .padding()
        }
    }
    var eventsDetail: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0.0) {
                Toggle(isOn: $showEpochs) {
                    Text("Show epochs")
                    Text("Color the epoch window along with event stamps")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
                
                Divider()
                
                LabeledContent {
                    Stepper("\(doc.contents.epochLength)", value: $doc.contents.epochLength, in: 10...500, step: 10)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("Epoch length")
                    Text("The number of samples that make up an epoch")
                }
                .padding(.vertical)

                
                Divider()
                
                VStack(spacing: 0.0) {
                    LabeledContent {
                        EmptyView()
                    } label: {
                        Text("Event types")
                        Text("Select event types to plot")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                    
                    VStack {
                        ForEach(doc.contents.eventTypes, id: \.self) { eventType in
                            HStack {
                                Button {
                                    if selectedEventTypes.contains(eventType) {
                                        selectedEventTypes.removeAll { eventType_ in
                                            eventType_ == eventType
                                        }
                                    } else {
                                        selectedEventTypes.append(eventType)
                                    }
                                } label: {
                                    if selectedEventTypes.contains(eventType) {
                                        Image(systemName: "circle.inset.filled")
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.borderless)
                                .padding(.trailing)
                                
                                LabeledContent {
                                    Text("\(doc.contents.events.filter({ event in event.type == eventType }).count)")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                } label: {
                                    Text(eventType)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Button("Deselect all") {
                            selectedEventTypes = []
                        }
                        
                        Button("Select all") {
                            selectedEventTypes = doc.contents.eventTypes
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                }
                .padding(.vertical)

                Divider()
            }
            .padding()
        }
    }
    
    var stackedPlot: some View {
        VStack(spacing: 0.0) {
            HStack(spacing: 0.0) {
                streamSidebar
                    .frame(width: 50)
                
                Divider()
                
                ZStack {
                    eventOverlay
                    
                    plot
                }
            }
            
            Divider()
            
            VStack {
                timeline
                
                stackedPlotBottomBar
            }
            .padding()
        }
    }
    var eventOverlay: some View {
        Canvas { context, size in
            let eventsToDraw = doc.contents.events.filter { event in
                guard selectedEventTypes.contains(event.type) else {
                    return false
                }
                
                let epochRange = (event.sampleIndex...(event.sampleIndex + doc.contents.epochLength - 1))
                
                return epochRange.contains(plottingWindowFirstSampleIndex) || sampleRange.contains(epochRange.lowerBound) || sampleRange.contains(epochRange.upperBound)
            }
            
            for event in eventsToDraw {
                let x = size.width * (CGFloat(event.sampleIndex - plottingWindowFirstSampleIndex + 1) / CGFloat(plottingWindowSampleSize))
                
                let eventPath = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                
                context.stroke(eventPath, with: .color(.red), lineWidth: 1.0)

                if showEpochs {
                    let epochEnd = size.width * (CGFloat(doc.contents.epochLength + event.sampleIndex - plottingWindowFirstSampleIndex + 1) / CGFloat(plottingWindowSampleSize))
                    
                    let eventEndPath = Path { path in
                        path.move(to: CGPoint(x: epochEnd, y: 0))
                        path.addLine(to: CGPoint(x: epochEnd, y: size.height))
                    }
                    
                    let epochPath = Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: epochEnd, y: 0))
                        path.addLine(to: CGPoint(x: epochEnd, y: size.height))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    
                    context.fill(epochPath, with: .color(.red.opacity(0.025)))
                    context.stroke(eventEndPath, with: .color(.red), style: StrokeStyle(lineWidth: 1.0, dash: [5]))
                }
            }
        }
    }
    var plot: some View {
        GeometryReader { proxy in
            let rowHeight = rowHeight(size: proxy.size)
            let verticalPadding = proxy.size.height * verticalPaddingProportion
            let absYLim = doc.contents.absoluteYLimit
            
            VStack(spacing: 0.0) {
                ForEach(selectedStreams.indices, id: \.self) { streamIndex in
                    let stream = selectedStreams[streamIndex]
                    
                    let points = TraceDocumentContents.sampleDataPoints(from: [stream], sampleRate: doc.contents.sampleRate, spliced: sampleRange)
                    
                    Chart(points) { point in
                        LineMark(
                            x: .value("time/s", point.timestamp),
                            y: .value("potential/mV", point.potential)
                        )
                        .foregroundStyle(by: .value("Electrode", point.electrode.symbol))
                    }
                    .chartXScale(domain: timeRange)
                    .chartYScale(domain: -absYLim...absYLim)
                    .chartYAxis(content: {
                        AxisMarks(position: .leading, values: [0.0]) { value in
                            AxisGridLine()
                        }
                    })
                    .chartXAxis(.hidden)
                    .chartLegend(.hidden)
                    .frame(height: rowHeight)
                    .drawingGroup()
                    .onHover { isHovering in
                        if isHovering {
                            hoveringOver = stream.id
                        } else {
                            hoveringOver = nil
                        }
                    }
                }
            }
            .padding(.vertical, verticalPadding / 2)
        }
    }
    var electrodeTick: some View {
        VStack {
            Divider()
        }
        .frame(width: 5)
    }
    var streamSidebar: some View {
        GeometryReader { proxy in
            let rowHeight = rowHeight(size: proxy.size)
            
            VStack(spacing: 0.0) {
                ForEach(selectedStreams) { stream in
                    HStack {
                        Text(stream.electrode.symbol)
                            .foregroundColor(hoveringOver == stream.id ? .accentColor : .primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        electrodeTick
                    }
                    .frame(height: rowHeight)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
    var timeline: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(.quaternaryLabelColor)))
            
            if let sampleCount = doc.contents.sampleCount {
                for event in doc.contents.events.filter({ event in
                    selectedEventTypes.contains(event.type)
                }) {
                    let timeProportion = CGFloat(event.sampleIndex + 1) / CGFloat(sampleCount)
                    
                    let x = size.width * timeProportion
                    
                    let linePath: Path = Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    
                    context.stroke(linePath, with: .color(.red), lineWidth: 1.0)
                    
                    if showEpochs {
                        let epochEnd = size.width * (CGFloat(doc.contents.epochLength + event.sampleIndex + 1) / CGFloat(sampleCount))
                        
                        let epochPath = Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: epochEnd, y: 0))
                            path.addLine(to: CGPoint(x: epochEnd, y: size.height))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        
                        let eventEndPath = Path { path in
                            path.move(to: CGPoint(x: epochEnd, y: 0))
                            path.addLine(to: CGPoint(x: epochEnd, y: size.height))
                        }
                        
                        context.fill(epochPath, with: .color(.red.opacity(0.1)))
                        context.stroke(eventEndPath, with: .color(.red), style: StrokeStyle(lineWidth: 1.0, dash: [2]))
                    }
                }
                
                switch visualisation {
                case .stackedPlot:
                    let frameWidth = size.width * (CGFloat(plottingWindowSampleSize) / CGFloat(sampleCount))
                    let xOffset = size.width * (CGFloat(plottingWindowFirstSampleIndex) / CGFloat(sampleCount))
                    let trailingBound = xOffset + frameWidth
                    
                    let windowPath = Path { path in
                        path.move(to: CGPoint(x: xOffset, y: 0))
                        path.addLine(to: CGPoint(x: xOffset, y: size.height))
                        path.addLine(to: CGPoint(x: trailingBound, y: size.height))
                        path.addLine(to: CGPoint(x: trailingBound, y: 0))
                    }
                    
                    context.fill(windowPath, with: .color(.accentColor.opacity(0.5)))
                case .scalpMap:
                    let xOffset = size.width * (CGFloat(scalpMapSampleIndexToDisplay) / CGFloat(sampleCount))
                    
                    let indicatorPath = Path { path in
                        path.move(to: CGPoint(x: xOffset, y: 0))
                        path.addLine(to: CGPoint(x: xOffset, y: size.height))
                    }
                    
                    context.stroke(indicatorPath, with: .color(.accentColor), lineWidth: 1.0)
                }
            }
        }
        .mask(Capsule())
        .frame(height: 10)
    }
    var stackedPlotBottomBar: some View {
        HStack {
            previousWindow
            
            shiftWindowLeft
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("#")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(plottingWindowFirstSampleIndex + 1)")
                        .font(.system(.title2, design: .monospaced))
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("\(doc.contents.time(at: plottingWindowFirstSampleIndex).format())")
                        .font(.system(.body, design: .monospaced))
                    
                    Text(" s")
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("#")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(plottingWindowFirstSampleIndex + plottingWindowSampleSize)")
                        .font(.system(.title2, design: .monospaced))
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("\(doc.contents.time(at: plottingWindowFirstSampleIndex + plottingWindowSampleSize).format())")
                        .font(.system(.body, design: .monospaced))
                    
                    Text(" s")
                }
                .foregroundColor(.secondary)
            }
            
            shiftWindowRight
            
            nextWindow
        }
        .disabled(visualisation != .stackedPlot)
    }
    
    var previousWindow: some View {
        Button(action: {
            plottingWindowFirstSampleIndex -= plottingWindowSampleSize
        }) {
            Image(systemName: "arrowtriangle.left.square")
        }
        .disabled((plottingWindowFirstSampleIndex - plottingWindowSampleSize) < 0)
        .keyboardShortcut(.leftArrow)
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
    var shiftWindowLeft: some View {
        Button(action: {
            plottingWindowFirstSampleIndex -= 1
        }) {
            Image(systemName: "backward.frame.fill")
        }
        .disabled(plottingWindowFirstSampleIndex - 1 < 0)
        .keyboardShortcut(.leftArrow, modifiers: [])
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
    var shiftWindowRight: some View {
        Button(action: {
            plottingWindowFirstSampleIndex += 1
        }) {
            Image(systemName: "forward.frame.fill")
        }
        .disabled((sampleRange.upperBound + 2) > doc.contents.sampleCount ?? 0)
        .keyboardShortcut(.rightArrow, modifiers: [])
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
    var nextWindow: some View {
        Button(action: {
            plottingWindowFirstSampleIndex += plottingWindowSampleSize
        }) {
            Image(systemName: "arrowtriangle.right.square")
        }
        .disabled((plottingWindowFirstSampleIndex + 2 * plottingWindowSampleSize) > doc.contents.sampleCount ?? 0)
        .keyboardShortcut(.rightArrow)
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
    
    var scalpMap: some View {
        VStack(spacing: 0.0) {
            ZStack {
                Canvas { context, size in
                    for stream in selectedStreams {
                        if let sector = stream.electrode.sector(in: size),
                           let potentialRange = doc.contents.potentialRange,
                           let color = stream.color(at: scalpMapSampleIndexToDisplay, globalPotentialRange: potentialRange) {
                            context.fill(sector, with: .color(color))
                        }
                    }
                }
                
                electrodeLabels
            }
            .padding(50)
            
            Divider()
            
            VStack {
                timeline
                
                scalpMapBottomBar
            }
            .padding()
        }
    }
    var electrodeLabels: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(selectedStreams) { stream in
                    if let location = stream.electrode.location?.cgPoint(in: proxy.size) {
                        VStack {
                            if showElectrodeLabels {
                                Text(stream.electrode.symbol).font(.headline)
                            }
                            if showElectrodePotentials {
                                Text("\(stream.samples[scalpMapSampleIndexToDisplay].format())").font(.system(.caption, design:.monospaced))
                            }
                        }
                        .position(x: location.x, y: location.y)
                    }
                }
            }
        }
    }
    
    var scalpMapBottomBar: some View {
        HStack {
            stepBackward10Button
                .keyboardShortcut(.leftArrow)
                .buttonStyle(.borderless)
            
            stepBackward1Button
                .keyboardShortcut(.leftArrow, modifiers: [])
                .buttonStyle(.borderless)
            
            Spacer()
            
            VStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("#")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(scalpMapSampleIndexToDisplay + 1)")
                        .font(.system(.title2, design: .monospaced))
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("\(doc.contents.time(at: scalpMapSampleIndexToDisplay).format())")
                        .font(.system(.body, design: .monospaced))
                    
                    Text(" s")
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            stepForward1Button
                .keyboardShortcut(.rightArrow, modifiers: [])
                .buttonStyle(.borderless)
            
            stepForward10Button
                .keyboardShortcut(.rightArrow)
                .buttonStyle(.borderless)
        }
    }
    
    var stepBackward1Button: some View {
        Button(action: {
            scalpMapSampleIndexToDisplay -= 1
        }) {
            Image(systemName: "backward.frame.fill")
        }.disabled(scalpMapSampleIndexToDisplay - 1 < 0)
    }
    var stepBackward10Button: some View {
        Button(action: {
            scalpMapSampleIndexToDisplay -= 10
        }) {
            Image(systemName: "gobackward.10")
        }.disabled(scalpMapSampleIndexToDisplay - 10 < 0)
    }
    var stepForward1Button: some View {
        Button(action: {
            scalpMapSampleIndexToDisplay += 1
        }) {
            Image(systemName: "forward.frame.fill")
        }
        .disabled(scalpMapSampleIndexToDisplay + 1 > doc.contents.sampleCount ?? 0)
    }
    var stepForward10Button: some View {
        Button(action: {
            scalpMapSampleIndexToDisplay += 10
        }) {
            Image(systemName: "goforward.10")
        }
        .disabled(scalpMapSampleIndexToDisplay + 10 > doc.contents.sampleCount ?? 0)
    }
    
    func rowHeight(size: CGSize) -> CGFloat {
        return Double(size.height * (1 - verticalPaddingProportion)) / Double(selectedStreams.count)
    }
    
    func processFile(urls: [URL]) {
        guard let url = urls.first else { alert = .fileImportFailure; return }
        guard let rawText = try? String(contentsOf: url) else { alert = .fileImportFailure; return }
        guard let streams = TraceDocumentContents.streams(from: rawText) else {  alert = .csvFormatInvalid; return }
    
        doc.contents.streams = streams
    }
}


#endif
