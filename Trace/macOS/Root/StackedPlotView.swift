//
//  StackedPlotView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct StackedPlotView: View {
    @Binding var doc: TraceDocument
    @Binding var selectedEventTypes: [String]
    @Binding var plottingWindowFirstSampleIndex: Int
    @Binding var plottingWindowSampleSize: Int
    @Binding var showEpochs: Bool
    @Binding var visualisation: RootView.Visualisation
    @Binding var scalpMapSampleIndexToDisplay: Int
    @Binding var selectedStreams: [Stream]
    
    var verticalPaddingProportion: CGFloat
    var potentialRange: ClosedRange<Double>
    
    var timeRange: ClosedRange<Double>
    var sampleRange: ClosedRange<Int>
    
    @Binding var mouseLocation: NSPoint?
    @Binding var lineWidth: CGFloat
    @Binding var marker: Int?
    
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
                                mouseLocation = nil
                            }
                        })
                        .trackMouse { location in
                            mouseLocation = location
                        }
                    
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
    var plot: some View {
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
                
                context.stroke(eventPath, with: .color(.red), lineWidth: lineWidth)

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
                    context.stroke(eventEndPath, with: .color(.red), style: StrokeStyle(lineWidth: lineWidth, dash: [5]))
                }
            }
            
            if let marker = marker {
                if sampleRange.contains(marker) {
                    let x = size.width * (CGFloat(marker - plottingWindowFirstSampleIndex + 1) / CGFloat(plottingWindowSampleSize))
                    let markerPath = Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    context.stroke(markerPath, with: .color(.green), lineWidth: lineWidth)
                }
            }
            
            if let mouseLocation = mouseLocation {
                let markerPathX = Path { path in
                    path.move(to: CGPoint(x: mouseLocation.x, y: 0))
                    path.addLine(to: CGPoint(x: mouseLocation.x, y: size.height))
                }
                let markerPathY = Path { path in
                    path.move(to: CGPoint(x: 0, y: mouseLocation.y))
                    path.addLine(to: CGPoint(x: size.width, y: mouseLocation.y))
                }
                context.stroke(markerPathX, with: .color(.green.opacity(0.25)), lineWidth: lineWidth)
                context.stroke(markerPathY, with: .color(.green.opacity(0.25)), lineWidth: lineWidth)
            }
            
            for (streamIndex, stream) in selectedStreams.enumerated() {
                let path = stream.path(plotSize: size, verticalPaddingProportion: verticalPaddingProportion, rowCount: selectedStreams.count, rowIndex: streamIndex, globalPotentialRange: potentialRange, firstSampleIndex: plottingWindowFirstSampleIndex, plottingWindowSize: plottingWindowSampleSize)
                
                context.stroke(path, with: .color(.accentColor), lineWidth: lineWidth)
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
                ForEach(selectedStreams) { stream in
                    HStack {
                        Text(stream.electrode.symbol)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        electrodeTick
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(height: proxy.size.height * (1 - verticalPaddingProportion))
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
                    
                    context.stroke(linePath, with: .color(.red), lineWidth: lineWidth)
                    
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
                        context.stroke(eventEndPath, with: .color(.red), style: StrokeStyle(lineWidth: lineWidth, dash: [2]))
                    }
                }
                
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
            
//            if let mouseLocation = mouseLocation {
//                Text("X: \(Double(mouseLocation.x).format()), Y: \(Double(mouseLocation.y).format())")
//            }
            
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
}
