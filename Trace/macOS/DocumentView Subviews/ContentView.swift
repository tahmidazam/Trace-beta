//
//  ContentView.swift
//  Trace
//
//  Created by Tahmid Azam on 28/11/2022.
//

import SwiftUI

struct ContentView: View {
    @Binding var doc: TraceDocument
    @Binding var streamIds: Set<Stream.ID>
    @Binding var tab: DocumentView.Tab
    
    var body: some View {
        Group {
            switch tab {
            case .streams: StreamsView(doc: $doc, streamIds: $streamIds)
            case .events: EmptyView()
            case .scalpMap: VisualiseView()
            case .plot: PlotView()
            case .study: EmptyView()
            }
        }
        .navigationSubtitle("\(doc.contents.streams.count) stream\(doc.contents.streams.count == 1 ? "" : "s")")
    }
}
