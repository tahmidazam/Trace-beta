//
//  ContentView.swift
//  Trace
//
//  Created by Tahmid Azam on 28/11/2022.
//

import SwiftUI
#if os(macOS)
struct ContentView: View {
    @Binding var doc: TraceDocument
    @Binding var streamIds: Set<Stream.ID>
    
    @Binding var tab: DocumentView.Tab
    
    var body: some View {
        Group {
            switch tab {
            case .streams: StreamsView(doc: $doc, streamIds: $streamIds)
            case .events: EventsView(doc: $doc)
            case .scalpMap: VisualiseView(doc: $doc)
            case .plot: PlotView()
            case .study: StudyView(doc: $doc)
            }
        }
        .navigationSubtitle("\(doc.contents.streams.count) stream\(doc.contents.streams.count == 1 ? "" : "s")")
    }
}
#endif
