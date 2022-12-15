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
    
    var electrodeColumnSize: CGFloat = 100.0
    
    var sortedStreams: [Stream] {
        return doc.contents.streams.sorted { lhs, rhs in
            if lhs.electrode.prefix == rhs.electrode.prefix {
                return lhs.electrode.suffix < rhs.electrode.suffix
            }
            
            return lhs.electrode.prefix.rawValue < rhs.electrode.prefix.rawValue
        }
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            plot
            
            Divider()
            
            HStack {
                Text(doc.contents.formattedSampleCount ?? "")
            }
            .padding()
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
    
    var plot: some View {
        HStack(spacing: 0.0) {
            GeometryReader { proxy in
                let rowHeight = Double(proxy.size.height) / Double(doc.contents.streams.count)
                
                ZStack {
                    VStack(spacing: 0.0) {
                        ForEach(sortedStreams.indices, id: \.self) { streamIndex in
                            let stream = sortedStreams[streamIndex]
                            
                            HStack(alignment: .firstTextBaseline, content: {
                                Text("\(streamIndex + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(stream.electrode.symbol)
                            })
                                .padding(.horizontal)
                                .frame(width: electrodeColumnSize, height: rowHeight, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(.vertical)
            .background(Color(.textBackgroundColor))
            .frame(width: electrodeColumnSize)
            
            Divider()
            
            GeometryReader { proxy in
                let rowHeight = Double(proxy.size.height) / Double(doc.contents.streams.count)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack {
                        ForEach(sortedStreams.indices, id: \.self) { streamIndex in
                            if let potentialRange = doc.contents.potentialRange {
                                let yLimit = max(abs(potentialRange.lowerBound), abs(potentialRange.upperBound))

                                let stream = sortedStreams[streamIndex]

                                let y = (rowHeight / 2) + Double(streamIndex) * rowHeight

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
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct PlotView_Previews: PreviewProvider {
    static var previews: some View {
        PlotView(doc: .constant(TraceDocument()))
    }
}
