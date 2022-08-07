//
//  StreamDetailView.swift
//  Trace
//
//  Created by Tahmid Azam on 29/07/2022.
//

import SwiftUI
import Charts

struct StreamDetailView: View {
    @Binding var doc: TraceDocument
    
    @State var stream: Stream
    
    var body: some View {
        if let potentialRange = doc.contents.potentialRange {
            Chart(stream.sampleDataPoints(at: doc.contents.sampleRate), id: \.self) { point in
                LineMark(
                    x: .value("time/s", point.timestamp),
                    y: .value("potential/mV", point.potential)
                )
                .lineStyle(StrokeStyle(lineWidth: 0.5))
            }
            .chartYScale(domain: potentialRange)
            .padding()
        }
    }
}
