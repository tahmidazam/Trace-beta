//
//  SidebarView.swift
//  Trace
//
//  Created by Tahmid Azam on 28/11/2022.
//

import SwiftUI

struct SidebarView: View {
    @Binding var tab: DocumentView.Tab
    
    var body: some View {
//        List(DocumentView.Tab.allCases, selection: $tab) { tab_ in
//            Label(tab_.rawValue.capitalized, systemImage: tab_.systemImage)
//        }
        List(selection: $tab) {
            Section("Data") {
                Label("Streams", systemImage: "tablecells").tag(DocumentView.Tab.streams)
                Label("Events", systemImage: "list.bullet").tag(DocumentView.Tab.events)
            }
            .collapsible(false)
            
            Section("Visualise") {
                Label("Scalp map", systemImage: "circle.dashed").tag(DocumentView.Tab.scalpMap)
                Label("Plot", systemImage: "chart.xyaxis.line").tag(DocumentView.Tab.plot)
            }
            .collapsible(false)
            
            Section {
                Label("Study details", systemImage: "person").tag(DocumentView.Tab.study)
            }
            .collapsible(false)
        }
        
    }
}
