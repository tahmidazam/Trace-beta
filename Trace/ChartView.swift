//
//  ChartView.swift
//  Trace
//
//  Created by Tahmid Azam on 29/07/2022.
//

import SwiftUI
import Charts

struct ChartView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var doc: TraceDocument
    
    var body: some View {
        NavigationStack {
            chart
                .navigationTitle("Chart")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: { toolbar })
        }
    }
    
    var chart: some View {
        Chart(TraceDocumentContents.sampleDataPoints(from: doc.contents.streams, sampleRate: doc.contents.sampleRate), id: \.self) {
            LineMark(
                x: .value("time/s", $0.timestamp),
                y: .value("potential/mV", $0.potential)
            )
            .foregroundStyle(by: .value("Electrode", $0.electrode.symbol))
            .lineStyle(StrokeStyle(lineWidth: 0.5))
        }
        .chartXScale(domain: 0...maxXScale)
        .chartLegend(.hidden)
        .padding()
    }
    
    var maxXScale: Double {
        (Double(1 / doc.contents.sampleRate) * Double(doc.contents.streams.first?.samples.count ?? 0))
    }
    var toolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .confirmationAction, content: { doneButton })
        }
    }
    
    var doneButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Done")
        }
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(doc: .constant(TraceDocument()))
    }
}
