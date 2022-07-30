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
    
    var stepSize = 100
    
    @State var firstIndex: Int = 0
    @State var lastIndex: Int = 100
    
    @State var loading = false
    
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
        .chartXScale(domain: doc.contents.time(at: firstIndex)...doc.contents.time(at: lastIndex))
        .chartLegend(.hidden)
        .padding()
    }
    
    var maxXScale: Double {
        (Double(1 / doc.contents.sampleRate) * Double(doc.contents.streams.first?.samples.count ?? 0))
    }
    var toolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .confirmationAction, content: { doneButton })
            
            ToolbarItemGroup(placement: .bottomBar, content: {
                stepBackward1Button
                
                Spacer()
                
                Text("Loading...").opacity(loading ? 1 : 0)
                
                Spacer()
                
                stepForward1Button
            })
        }
    }
    
    var doneButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Done")
        }
    }
    var stepBackward1Button: some View {
        Button(action: {
            firstIndex -= stepSize
            lastIndex -= stepSize
        }) {
            Image(systemName: "backward.frame.fill")
        }.disabled(firstIndex - stepSize < 0)
    }
    var stepForward1Button: some View {
        Button(action: {
            loading = true
            firstIndex += stepSize
            lastIndex += stepSize
            loading = false
        }) {
            Image(systemName: "forward.frame.fill")
        }
        .disabled(firstIndex + stepSize > doc.contents.sampleCount ?? 0)
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(doc: .constant(TraceDocument()))
    }
}
