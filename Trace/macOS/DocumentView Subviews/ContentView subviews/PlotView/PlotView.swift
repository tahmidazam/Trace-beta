//
//  PlotView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/11/2022.
//

import SwiftUI
import Charts

struct PlotView: View {
    @Binding var doc: TraceDocument
    
    
    @State var chartHeightScaleFactor = 1.0
    @State var chartWidthScaleFactor = 1.0
    
    @GestureState var scale: CGFloat = 1.0
    
    var electrodeColumnSize: CGFloat = 75.0
    var potentialRange: ClosedRange<Double> {
        doc.contents.potentialRange ?? 0...0
    }
    var sortedStreams: [Stream] {
        return doc.contents.streams.sorted { lhs, rhs in
            if lhs.electrode.prefix == rhs.electrode.prefix {
                return lhs.electrode.suffix < rhs.electrode.suffix
            }
            
            return lhs.electrode.prefix.rawValue < rhs.electrode.prefix.rawValue
        }
    }
    
    @State var mouseLocation: CGPoint? = nil
    
    var body: some View {
        VStack(spacing: 0.0) {
            HSplitView {
                leftColumn
                    .frame(width: electrodeColumnSize)
                
                traces
            }
            
            Divider()
            
            bottomBar
        }
            .toolbar {
                ToolbarItemGroup {
                    Label("Vertical chart scale", systemImage: "arrow.up.and.line.horizontal.and.arrow.down")
                    
                    chartHeightScaleFactorPicker
                    
                    Label("Horizontal chart scale", systemImage: "arrow.left.and.line.vertical.and.arrow.right")
                    
                    chartWidthScaleFactorPicker
                }
            }
    }
    
    var chartHeightScaleFactorPicker: some View {
        Picker(selection: $chartHeightScaleFactor) {
            ForEach([0.5, 0.75, 1.0, 2.0, 3.0, 4.0, 5.0], id: \.self) { scaleFactor in
                Text(scaleFactor, format: .percent)
            }
        } label: {
            Label("Vertical chart scale", systemImage: "arrow.up.and.line.horizontal.and.arrow.down")
        }
        
    }
    var chartWidthScaleFactorPicker: some View {
        Picker(selection: $chartWidthScaleFactor) {
            ForEach([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0], id: \.self) { scaleFactor in
                Text(scaleFactor, format: .percent)
            }
        } label: {
            Label("Horizontal chart scale", systemImage: "arrow.left.and.line.vertical.and.arrow.right")
        }
    }
    
    var verticalPaddingProportion = 0.1
    
    var bottomBar: some View {
        HStack {
            Text(doc.contents.formattedSampleCount ?? "")
            
            Spacer()
            
            if let mouseLocation = mouseLocation {
                Text("x: \(mouseLocation.x), y: \(mouseLocation.y)")
            }
        }
        .padding()
    }
    var leftColumn: some View {
        GeometryReader { proxy in
            let rowHeight = rowHeight(size: proxy.size)
            
            VStack(spacing: 0.0) {
                ForEach(doc.contents.streams) { stream in
                    Text(stream.electrode.symbol)
                        .padding(.horizontal)
                        .frame(height: rowHeight)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
    
    func rowHeight(size: CGSize) -> CGFloat {
        return Double(size.height * (1 - verticalPaddingProportion)) / Double(doc.contents.streams.count)
    }
    
    var traces: some View {
        GeometryReader { proxy in
            let rowHeight = rowHeight(size: proxy.size)
            
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack {
                    ForEach(sortedStreams.indices, id: \.self) { streamIndex in
                        let stream = sortedStreams[streamIndex]
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
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        
    }
}

struct PlotView_Previews: PreviewProvider {
    static var previews: some View {
        PlotView(doc: .constant(TraceDocument()))
    }
}
