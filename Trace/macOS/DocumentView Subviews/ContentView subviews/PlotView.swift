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
    
    var sortedStreams: [Stream] {
        return doc.contents.streams.sorted { lhs, rhs in
            if lhs.electrode.prefix == rhs.electrode.prefix {
                return lhs.electrode.suffix < rhs.electrode.suffix
            }
            
            return lhs.electrode.prefix.rawValue < rhs.electrode.prefix.rawValue
        }
    }
    
    var body: some View {
        Group {
            GeometryReader { proxy in
                let chartHeight = Double(proxy.size.height) / Double(doc.contents.streams.count)
                
                ZStack {
                    ForEach(sortedStreams.indices, id: \.self) { streamIndex in
                        let stream = sortedStreams[streamIndex]
                        
                        let x = (proxy.size.width - 50) / 2
                        let y = (chartHeight / 2) + Double(streamIndex) * chartHeight
                        
                        HStack(alignment: .center) {
                            Text(stream.electrode.symbol)
                                .frame(width: 50, alignment: .trailing)

                            if let potentialRange = doc.contents.potentialRange {
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
                            }
                        }
                        .frame(height: chartHeight * chartHeightScaleFactor)
                        .position(x: x, y: y)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem {
                Picker(selection: $chartHeightScaleFactor) {
                    ForEach([0.5, 0.75, 1.0, 2.0, 3.0, 4.0, 5.0], id: \.self) { scaleFactor in
                        Text(scaleFactor, format: .percent)
                    }
                } label: {
                    Text("Zoom")
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
