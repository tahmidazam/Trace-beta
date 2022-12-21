//
//  StackedPlotView.swift
//  Trace
//
//  Created by Tahmid Azam on 20/12/2022.
//

import SwiftUI
import Charts

struct StackedPlotView: View {
    @Binding var doc: TraceDocument
    
    enum StackedPlotViewSheet: Identifiable {
        var id: Self { self }
        
        case editStreamFilter
    }
    @State var sheetPresented: StackedPlotViewSheet? = nil
    
    @State var chartHeightScaleFactor = 1.0
    @State var chartWidthScaleFactor = 1.0
    
    @State var mouseLocation: CGPoint? = nil
    @State var plotSize: CGSize = .zero
    @State var scrollOffset: CGFloat = 0.0
    
    let verticalPaddingProportion = 0.1
    
    var potentialRange: ClosedRange<Double> {
        doc.contents.potentialRange ?? 0...0
    }
    
    @State var selectedStreams: [Stream] = []
    
    @State var marker: Int? = nil
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(spacing: 0.0) {
                streamSidebar
                    .frame(width: 50)
                
                Divider()
                
                ZStack {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onHover(perform: { isHovering in
                            if !isHovering {
                                mouseLocation = nil
                            }
                        })
                        .trackMouse { location in
                            mouseLocation = CGPoint(x: location.x, y: location.y)
                        }
                    
                    stackedPlot
                }
            }
            
            Divider()
            
            timingBottombar
        }
        .task {
            selectedStreams = doc.contents.streams
        }
        .onChange(of: selectedStreams) { newValue in
            selectedStreams = newValue.sorted(by: { lhs, rhs in
                if lhs.electrode.prefix == rhs.electrode.prefix {
                    return lhs.electrode.suffix < rhs.electrode.suffix
                }
                
                return lhs.electrode.prefix.rawValue < rhs.electrode.prefix.rawValue
            })
        }
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    if let marker = marker {
                        ForEach(doc.contents.eventTypes, id: \.self) { eventType in
                            Button("Add \(eventType) event at sample \(marker + 1)") {
                                doc.contents.events.append(Event(sampleIndex: marker, type: eventType))
                            }
                        }
                    }
                } label: {
                    Label("Add event at marker", systemImage: "plus")
                }
                .disabled(marker == nil)
                
                Button {
                    sheetPresented = .editStreamFilter
                } label: {
                    Label("Edit stream filter...", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(item: $sheetPresented) { sheet in
            switch sheet {
            case .editStreamFilter: EditStreamFilterView(doc: $doc, selectedStreams: $selectedStreams)
            }
        }
    }
    
    var stackedPlot: some View {
        GeometryReader { (proxy: GeometryProxy) in
            let rowHeight = rowHeight(size: proxy.size)
            
            ObservableScrollView(axis: .horizontal, showsIndicators: false, scrollOffset: $scrollOffset) { _ in
                ZStack {
                    ForEach(selectedStreams.indices, id: \.self) { streamIndex in
                        let stream = selectedStreams[streamIndex]
                        let y = (verticalPaddingProportion / 2) * proxy.size.height + (rowHeight / 2) + Double(streamIndex) * rowHeight
                        let yLimit = max(abs(potentialRange.lowerBound), abs(potentialRange.upperBound))

                        Chart(TraceDocumentContents.sampleDataPoints(from: [stream], sampleRate: doc.contents.sampleRate)) { point in
                            LineMark(
                                x: .value("time/s", point.timestamp),
                                y: .value("potential/mV", point.potential)
                            )
                            .foregroundStyle(by: .value("Electrode", point.electrode.symbol))
                        }
                        .chartYScale(domain: -yLimit...yLimit)
                        .chartYAxis(content: {
                            AxisMarks(position: .leading, values: [0.0]) { value in
                                AxisGridLine()
                            }
                        })
                        .chartXAxis(.hidden)
                        .chartLegend(.hidden)
                        .frame(width: (proxy.size.width) * chartWidthScaleFactor, height: rowHeight * chartHeightScaleFactor)
                        .position(x: ((proxy.size.width) * chartWidthScaleFactor) / 2, y: y)
                    }

                    Canvas { context, size in
                        if let sampleCount = doc.contents.sampleCount {
                            for event in doc.contents.events {
                                let timeProportion = Double(event.sampleIndex + 1) / Double(sampleCount)

                                let x = size.width * timeProportion

                                let linePath: Path = Path { path in
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: size.height))
                                }

                                context.stroke(linePath, with: .color(.red), lineWidth: 1.0)
                            }

                            if let marker = marker {
                                let timeProportion = Double(marker + 1) / Double(sampleCount)

                                let x = size.width * timeProportion

                                let linePath: Path = Path { path in
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: size.height))
                                }

                                context.stroke(linePath, with: .color(.green), lineWidth: 1.0)
                            }

                            if let xProportion = xProportion {
                                let timeProportion = xProportion

                                let x = size.width * timeProportion

                                let linePath: Path = Path { path in
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: size.height))
                                }

                                context.stroke(linePath, with: .color(.green.opacity(0.5)), lineWidth: 1.0)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        marker = sampleHoveredOver()
                    }
                }
            }
            .task {
                plotSize = proxy.size
            }
        }
    }
    
    var streamSidebar: some View {
        GeometryReader { proxy in
            let rowHeight = rowHeight(size: proxy.size)
            
            VStack(spacing: 0.0) {
                ForEach(selectedStreams) { stream in
                    HStack {
                        Text(stream.electrode.symbol)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        electrodeTick
                    }
                    .frame(height: rowHeight)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
    
    var timingBottombar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Plotting \(selectedStreams.count) of \(doc.contents.streams.count) streams")
                    .font(.headline)
                
                if let duration = doc.contents.duration,
                   let sampleCount = doc.contents.sampleCount {
                    Text("\(sampleCount) sample\(sampleCount == 1 ? "" : "s"), \(duration.format()) s")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack {
                if let streamHoveredOver = streamHoveredOver(),
                   let sampleHoveredOver = sampleHoveredOver() {
                    Label("\(streamHoveredOver.electrode.symbol), sample \(sampleHoveredOver),  \(doc.contents.time(at: sampleHoveredOver).format()) s", systemImage: "scope")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                
                if let xProportion = xProportion,
                   let yProportion = yProportion {
                    Text("x: \(xProportion.format()), y: \(yProportion.format())")
                        .font(.system(.subheadline, design: .monospaced))
                }
            }
            
            if let marker = marker {
                Label("sample \(marker + 1), \(doc.contents.time(at: marker)) s", systemImage: "rectangle.connected.to.line.below")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Label {
                Text(chartWidthScaleFactor, format: .percent)
            } icon: {
                Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
            }
            
            Stepper(value: $chartWidthScaleFactor, in: 1...10) {
                EmptyView()
            }
            .labelsHidden()
            
            Label {
                Text(chartWidthScaleFactor, format: .percent)
            } icon: {
                Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
            }
            
            Stepper(value: $chartHeightScaleFactor, in: 0.5...5.0) {
                EmptyView()
            }
            .labelsHidden()
        }
        .padding()
    }
    
    func streamHoveredOver() -> Stream? {
        guard plotSize != .zero else {
            return nil
        }
        
        guard let mouseLocation = mouseLocation else {
            return nil
        }
        
        let paddingSize = plotSize.height * verticalPaddingProportion
        let isPastTopPadding = mouseLocation.y >= (paddingSize / 2)
        let isBeforeBottomPadding = mouseLocation.y <= plotSize.height - (paddingSize / 2)
        
        guard isPastTopPadding
                && isBeforeBottomPadding else {
            return nil
        }
        
        var streamIndex = -1
        
        var total = 0.0
        
        while total <= mouseLocation.y - paddingSize / 2 {
            total += rowHeight(size: plotSize)
            streamIndex += 1
        }
        
        print(streamIndex)
        
        guard selectedStreams.indices.contains(streamIndex) else {
            return nil
        }
        
        return selectedStreams[streamIndex]
    }
    
    func sampleHoveredOver() -> Int? {
        guard let xProportion = xProportion else {
            return nil
        }
        
        guard let sampleCount = doc.contents.sampleCount else {
            return nil
        }
        
        return Int(round(Double(sampleCount) * xProportion))
    }
    
    var xProportion: Double? {
        guard let mouseLocation = mouseLocation else {
            return nil
        }
        
        return (mouseLocation.x + scrollOffset) / (plotSize.width * chartWidthScaleFactor)
    }
    
    var yProportion: Double? {
        guard let mouseLocation = mouseLocation else {
            return nil
        }
        
        return mouseLocation.y / plotSize.height
    }
    
    var electrodeTick: some View {
        VStack {
            Divider()
        }
        .frame(width: 5)
    }
    
    func rowHeight(size: CGSize) -> CGFloat {
        return Double(size.height * (1 - verticalPaddingProportion)) / Double(selectedStreams.count)
    }
}
