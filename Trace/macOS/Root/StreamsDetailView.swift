//
//  StreamsDetailView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct StreamsDetailView: View {
    @Binding var doc: TraceDocument
    @Binding var selectedStreams: [Stream]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0.0) {
                LabeledContent {
                    EmptyView()
                } label: {
                    Text("Streams")
                    Text("Select the streams to plot.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
                
                ForEach(Electrode.Prefix.allCases) { electrodePrefix in
                    let filteredStreams = doc.contents.streams.filter({ $0.electrode.prefix == electrodePrefix })
                    
                    DisclosureGroup {
                        VStack {
                            ForEach(filteredStreams) { stream in
                                HStack {
                                    Button {
                                        if selectedStreams.contains(stream) {
                                            selectedStreams.removeAll { stream_ in
                                                stream_.id == stream.id
                                            }
                                        } else {
                                            selectedStreams.append(stream)
                                        }
                                    } label: {
                                        if selectedStreams.contains(stream) {
                                            Image(systemName: "circle.inset.filled")
                                                .foregroundColor(.accentColor)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                    .padding(.trailing)
                                    
                                    Text(stream.electrode.symbol)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    } label: {
                        LabeledContent {
                            Text("\(filteredStreams.count)")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } label: {
                            Text(electrodePrefix.rawValue.capitalized)
                        }
                    }
                }
                
                HStack {
                    Button("Deselect all") {
                        selectedStreams = []
                    }
                    
                    Button("Select all") {
                        selectedStreams = doc.contents.streams
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                
                Divider()
            }
            .padding()
        }
    }
}
