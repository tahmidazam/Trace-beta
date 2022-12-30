//
//  StackedPlotView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct StackedPlotView: View {
    @Binding var doc: TraceDocument
    @ObservedObject var plottingState: PlottingState
    
    var potentialRange: ClosedRange<Double>
    var timeRange: ClosedRange<Double>
    var sampleRange: ClosedRange<Int>
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(spacing: 0.0) {
                streamSidebar
                    .frame(width: 50)
                
                Divider()
                
                ZStack {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onHover(perform: { isHovering in
                            if !isHovering {
                                plottingState.mouseLocation = nil
                            }
                        })
                        .trackMouse { location in
                            plottingState.mouseLocation = location
                        }
                    
                    plot
                }
            }
            
            Divider()
            
            VStack {
                TimelineView(doc: $doc, plottingState: plottingState)
                
                stackedPlotBottomBar
            }
            .padding()
        }
    }
    var plot: some View {
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
                    
                    context.fill(epochPath, with: .color(.red.opacity(0.025)))
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
            
            for (streamIndex, stream) in plottingState.selectedStreams.enumerated() {
                let path = stream.path(plotSize: size, verticalPaddingProportion: PlottingState.verticalPaddingProportion, rowCount: plottingState.selectedStreams.count, rowIndex: streamIndex, globalPotentialRange: potentialRange, firstSampleIndex: plottingState.windowStartIndex, plottingWindowSize: plottingState.windowSize)
                
                context.stroke(path, with: .color(.accentColor), lineWidth: plottingState.lineWidth)
            }
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
                    Text("\(doc.contents.time(at: plottingState.windowStartIndex).format())")
                        .font(.system(.body, design: .monospaced))
                    
                    Text(" s")
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
//            if let mouseLocation = mouseLocation {
//                Text("X: \(Double(mouseLocation.x).format()), Y: \(Double(mouseLocation.y).format())")
//            }
            
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
                    Text("\(doc.contents.time(at: plottingState.windowStartIndex + plottingState.windowSize).format())")
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
            plottingState.windowStartIndex -= 1
        }) {
            Image(systemName: "backward.frame.fill")
        }
        .disabled(plottingState.windowStartIndex - 1 < 0)
        .keyboardShortcut(.leftArrow, modifiers: [])
        .buttonStyle(.borderless)
        .controlSize(.large)
    }
    var shiftWindowRight: some View {
        Button(action: {
            plottingState.windowStartIndex += 1
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
