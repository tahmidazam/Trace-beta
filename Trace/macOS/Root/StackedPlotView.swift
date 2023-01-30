//
//  StackedPlotView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI
import Charts

struct StackedPlotView: View {
    @Binding var doc: TraceDocument
    @ObservedObject var plottingState: PlottingState
    
    var potentialRange: ClosedRange<Double>
    var timeRange: ClosedRange<Double>
    var sampleRange: ClosedRange<Int>
    var bound: Double {
        max(abs(plottingState.visiblePotentialRange.upperBound), abs(plottingState.visiblePotentialRange.lowerBound))
    }
    
    @GestureState var magnifyBy: CGFloat = 1.0
    @GestureState var dragAmount = CGSize.zero
    
    var magnification: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { currentState, gestureState, transaction in
                withAnimation {
                    gestureState = currentState
                }
            }
    }
    var drag: some Gesture {
        DragGesture().updating($dragAmount) { value, state, transaction in
            state = value.translation
        }
    }
#if os(macOS)
    var body: some View {
        if plottingState.selectedStreams.isEmpty {
            noStreamsSelectedView
        } else {
            VStack(spacing: 0.0) {
                HStack(spacing: 0.0) {
                    streamSidebar
                        .frame(width: 50)
                    Divider()
                    plot
                    
                    Divider()
                }
                
                Divider()
                
                VStack {
                    Timeline(doc: $doc, plottingState: plottingState)
                    
                    stackedPlotBottomBar
                }
                .padding()
            }
        }
    }
#else
    var body: some View {
        VStack(spacing: 0.0) {
            Divider()
            HStack(spacing: 0.0) {
                streamSidebar
                    .frame(width: 50)
                
                Divider()
                
                ZStack {
                    plot
                }
            }
            .scaleEffect(magnifyBy)
            .offset(dragAmount)
            .gesture(SimultaneousGesture(drag, magnification))
            .mask(Rectangle())
            
            Divider()
        
            Timeline(doc: $doc, plottingState: plottingState)
                .padding()
            
            Divider()
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar, content: {
                stackedPlotBottomBar
            })
        }
    }
#endif
    
    var plot: some View {
        ZStack {
            GeometryReader { proxy in
                ForEach(plottingState.selectedStreams.indices, id: \.self) { streamIndex in
                    let unit = proxy.size.height / CGFloat(plottingState.selectedStreams.count)
                    let multiplier = CGFloat(streamIndex) + 0.5
                    let x = proxy.size.width * 0.5
                    let y = multiplier * unit
                    
                    Divider()
                        .position(x: x, y: y)
                }
            }
            Canvas { context, size in
                let eventsToDraw = doc.contents.events.filter { event in
                    guard plottingState.selectedEventTypes.contains(event.type) else {
                        return false
                    }
                    
                    let epochRange = (event.sampleIndex...(event.sampleIndex + doc.contents.epochLength - 1))
                    
                    return epochRange.contains(plottingState.windowStartIndex) || sampleRange.contains(epochRange.lowerBound) || sampleRange.contains(epochRange.upperBound)
                }
                for event in eventsToDraw {
                    let x = size.width * (CGFloat(event.sampleIndex - plottingState.windowStartIndex + 1) / CGFloat(plottingState.windowSize))
                    
                    let eventPath = Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    
                    context.stroke(eventPath, with: .color(.red), lineWidth: plottingState.lineWidth)
                    
                    if plottingState.showEpochs {
                        let epochEnd = size.width * (CGFloat(doc.contents.epochLength + event.sampleIndex - plottingState.windowStartIndex + 1) / CGFloat(plottingState.windowSize))
                        
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
                        
                        context.fill(epochPath, with: .color(.red.opacity(plottingState.epochFillOpacity)))
                        context.stroke(eventEndPath, with: .color(.red), style: StrokeStyle(lineWidth: plottingState.lineWidth, dash: [5]))
                    }
                }
                if let marker = plottingState.marker {
                    if sampleRange.contains(marker) {
                        let x = size.width * (CGFloat(marker - plottingState.windowStartIndex + 1) / CGFloat(plottingState.windowSize))
                        let markerPath = Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        context.stroke(markerPath, with: .color(.green), lineWidth: plottingState.lineWidth)
                    }
                }
#if os(macOS)
                if let mouseLocation = plottingState.mouseLocation {
                    let markerPathX = Path { path in
                        path.move(to: CGPoint(x: mouseLocation.x, y: 0))
                        path.addLine(to: CGPoint(x: mouseLocation.x, y: size.height))
                    }
                    let markerPathY = Path { path in
                        path.move(to: CGPoint(x: 0, y: mouseLocation.y))
                        path.addLine(to: CGPoint(x: size.width, y: mouseLocation.y))
                    }
                    context.stroke(markerPathX, with: .color(.green.opacity(0.25)), lineWidth: plottingState.lineWidth)
                    context.stroke(markerPathY, with: .color(.green.opacity(0.25)), lineWidth: plottingState.lineWidth)
                }
#endif
            }
            if plottingState.colorLinePlot {
                ZStack {
                    GeometryReader { proxy in
                        VStack(spacing: 0.0) {
                            let rowHeight: CGFloat = (proxy.size.height * (1 - PlottingState.verticalPaddingProportion)) / Double(plottingState.selectedStreams.count)
                            
                            ForEach(plottingState.selectedStreams.indices, id: \.self) { _ in
                                LinearGradient(colors: [.red, .yellow, .green, .cyan, .blue], startPoint: .top, endPoint: .bottom)
                                    .frame(height: rowHeight)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .mask {
                        Canvas { context, size in
                            for (streamIndex, stream) in plottingState.selectedStreams.enumerated() {
                                let path = stream.path(plotSize: size, verticalPaddingProportion: PlottingState.verticalPaddingProportion, rowCount: plottingState.selectedStreams.count, rowIndex: streamIndex, globalPotentialRange: plottingState.visiblePotentialRange, firstSampleIndex: plottingState.windowStartIndex, plottingWindowSize: plottingState.windowSize, pointsPerCGPoint: plottingState.pointsPerCGPoint)
                                
                                context.stroke(path, with: .color(.black), lineWidth: plottingState.lineWidth)
                            }
                        }
                    }
                }
            } else {
                Canvas { context, size in
                    for (streamIndex, stream) in plottingState.selectedStreams.enumerated() {
                        let path = stream.path(plotSize: size, verticalPaddingProportion: PlottingState.verticalPaddingProportion, rowCount: plottingState.selectedStreams.count, rowIndex: streamIndex, globalPotentialRange: plottingState.visiblePotentialRange, firstSampleIndex: plottingState.windowStartIndex, plottingWindowSize: plottingState.windowSize, pointsPerCGPoint: plottingState.pointsPerCGPoint)
                        
                        context.stroke(path, with: .color(.accentColor), lineWidth: plottingState.lineWidth)
                    }
                }
            }
        }
        .background(Color("PlotBackground"))
    }
    var electrodeTick: some View {
        VStack {
            Divider()
        }
        .frame(width: 5)
    }
    var streamSidebar: some View {
        GeometryReader { proxy in
            VStack(spacing: 0.0) {
                ForEach(plottingState.selectedStreams) { stream in
                    HStack {
                        Text(stream.electrode.symbol)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        electrodeTick
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(height: proxy.size.height * (1 - PlottingState.verticalPaddingProportion))
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
    var noStreamsSelectedView: some View {
        Text("No streams selected")
            .font(.title3)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
#if os(macOS)
    var stackedPlotBottomBar: some View {
        HStack {
            previousWindow
            
            shiftWindowLeft
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("#")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(plottingState.windowStartIndex + 1)")
                        .font(.system(.title2, design: .monospaced))
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("\(doc.contents.time(at: plottingState.windowStartIndex).formatDuration())")
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
                    
                    Text("\(plottingState.windowStartIndex + plottingState.windowSize)")
                        .font(.system(.title2, design: .monospaced))
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("\(doc.contents.time(at: plottingState.windowStartIndex + plottingState.windowSize).formatDuration())")
                        .font(.system(.body, design: .monospaced))
                    
                    Text(" s")
                }
                .foregroundColor(.secondary)
            }
            
            shiftWindowRight
            
            nextWindow
        }
        .disabled(plottingState.visualisation != PlottingState.Visualisation.stackedPlot)
    }
#else
    var stackedPlotBottomBar: some View {
        HStack {
            previousWindow
            
            shiftWindowLeft
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("#")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                    
                    Text("\(plottingState.windowStartIndex + 1)")
                        .font(.system(.subheadline, design: .monospaced).bold())
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("\(doc.contents.time(at: plottingState.windowStartIndex).format())")
                        .font(.system(.caption, design: .monospaced))
                    
                    Text(" s")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            
            Spacer()
            
            VStack(alignment: .trailing) {
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("#")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                    
                    Text("\(plottingState.windowStartIndex + plottingState.windowSize)")
                        .font(.system(.subheadline, design: .monospaced).bold())
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("\(doc.contents.time(at: plottingState.windowStartIndex + plottingState.windowSize).format())")
                        .font(.system(.caption, design: .monospaced))
                    
                    Text(" s")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            shiftWindowRight
            
            nextWindow
        }
        .disabled(plottingState.visualisation != PlottingState.Visualisation.stackedPlot)
    }
#endif
    
    var previousWindow: some View {
        Button(action: {
            plottingState.windowStartIndex -= plottingState.windowSize
        }) {
            Image(systemName: "arrowtriangle.left.square")
        }
        .disabled((plottingState.windowStartIndex - plottingState.windowSize) < 0)
        .keyboardShortcut(.leftArrow)
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
    var shiftWindowLeft: some View {
        Button(action: {
            plottingState.windowStartIndex -= plottingState.stepSize
        }) {
            Image(systemName: "backward.frame.fill")
        }
        .disabled(plottingState.windowStartIndex - plottingState.stepSize < 0)
        .keyboardShortcut(.leftArrow, modifiers: [])
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
    var shiftWindowRight: some View {
        Button(action: {
            plottingState.windowStartIndex += plottingState.stepSize
        }) {
            Image(systemName: "forward.frame.fill")
        }
        .disabled((sampleRange.upperBound + 1 + plottingState.stepSize) > doc.contents.sampleCount ?? 0)
        .keyboardShortcut(.rightArrow, modifiers: [])
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
    var nextWindow: some View {
        Button(action: {
            plottingState.windowStartIndex += plottingState.windowSize
        }) {
            Image(systemName: "arrowtriangle.right.square")
        }
        .disabled((plottingState.windowStartIndex + 2 * plottingState.windowSize) > doc.contents.sampleCount ?? 0)
        .keyboardShortcut(.rightArrow)
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
}
