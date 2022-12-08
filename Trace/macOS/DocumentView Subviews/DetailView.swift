//
//  DetailView.swift
//  Trace
//
//  Created by Tahmid Azam on 28/11/2022.
//

import SwiftUI

#if os(macOS)
struct DetailView: View {
    @Binding var doc: TraceDocument
    @Binding var streamIds: Set<Stream.ID>
    @Binding var tab: DocumentView.Tab
    
    var body: some View {
        Group {
            switch tab {
            case .streams: StreamDetailView(doc: $doc, streamIds: $streamIds, tab: $tab)
            case .events: EmptyView()
            case .scalpMap: EmptyView()
            case .plot: EmptyView()
            case .study: EmptyView()
            }
        }
    }
}
#endif
