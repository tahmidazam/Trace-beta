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
        HSplitView {
            content
                .frame(minWidth: 100, idealWidth: 200)
            
            StreamDetailView(doc: $doc, streamIds: $streamIds)
        }
    }
    
    var content: some View {
//        Table(doc.contents.streams, selection: $streamIds) {
//            TableColumn("") { stream in
//                Group {
//                    switch stream.electrode.generalArea {
//                    case .left: Image(systemName: "circle.lefthalf.filled")
//                    case .central: Image(systemName: "circle.and.line.horizontal").rotationEffect(.degrees(90))
//                    case .right: Image(systemName: "circle.righthalf.filled")
//                    }
//                }
//                .frame(width: 30.0)
//            }
//
//            TableColumn("Symbol") { stream in
//                Text(stream.electrode.symbol)
//            }
//
//            TableColumn("Prefix") { stream in
//                Text(stream.electrode.prefix.rawValue)
//                    .foregroundColor(.secondary)
//            }
//
//            TableColumn("General area") { stream in
//                Text(stream.electrode.generalArea.rawValue)
//                    .foregroundColor(.secondary)
//            }
//
//            TableColumn("Minimum") { stream in
//                if let potentialRange = stream.potentialRange {
//                    Text(potentialRange.lowerBound.format())
//                        .foregroundColor(.secondary)
//                }
//            }
//
//            TableColumn("Maximum") { stream in
//                if let potentialRange = stream.potentialRange {
//                    Text(potentialRange.upperBound.format())
//                        .foregroundColor(.secondary)
//                }
//            }
//        }
        
        
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
}
