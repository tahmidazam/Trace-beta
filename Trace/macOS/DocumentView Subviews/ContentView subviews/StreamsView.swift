//
//  ElectrodesView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/11/2022.
//

import SwiftUI

struct StreamsView: View {
    @Binding var doc: TraceDocument
    @Binding var streamIds: Set<Electrode.ID>
    
    var body: some View {
        NavigationStack {
            List(selection: $streamIds) {
                ForEach(Electrode.Prefix.allCases) { electrodePrefix in
                    Section(electrodePrefix.rawValue.capitalized) {
                        ForEach(doc.contents.streams.filter({ $0.electrode.prefix == electrodePrefix })) { stream in
                            Label {
                                Text(stream.electrode.symbol)
                            } icon: {
                                switch stream.electrode.generalArea {
                                case .left: Image(systemName: "circle.lefthalf.filled")
                                case .central: Image(systemName: "circle.and.line.horizontal").rotationEffect(.degrees(90))
                                case .right: Image(systemName: "circle.righthalf.filled")
                                }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: SwiftUI.ToolbarItemPlacement.primaryAction) {
                Button {
                    
                } label: {
                    Label("Import data", systemImage: "square.and.arrow.down")
                }
            }
        }
    }
}
