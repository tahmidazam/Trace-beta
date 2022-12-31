//
//  StreamsDetailView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct StreamsDetailView: View {
    @Binding var doc: TraceDocument
    @ObservedObject var plottingState: PlottingState
    
    #if os(macOS)
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
                                        if plottingState.selectedStreams.contains(stream) {
                                            plottingState.selectedStreams.removeAll { stream_ in
                                                stream_.id == stream.id
                                            }
                                        } else {
                                            plottingState.selectedStreams.append(stream)
                                        }
                                    } label: {
                                        if plottingState.selectedStreams.contains(stream) {
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
                        plottingState.selectedStreams = []
                    }
                    
                    Button("Select all") {
                        plottingState.selectedStreams = doc.contents.streams
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                
                Divider()
            }
            .padding()
        }
    }
    #else
    var body: some View {
        List {
            ForEach(Electrode.Prefix.allCases) { electrodePrefix in
                let filteredStreams = doc.contents.streams.filter({ $0.electrode.prefix == electrodePrefix })
                
                Section(electrodePrefix.rawValue.capitalized) {
                    ForEach(filteredStreams) { stream in
                        HStack {
                            Button {
                                if plottingState.selectedStreams.contains(stream) {
                                    plottingState.selectedStreams.removeAll { stream_ in
                                        stream_.id == stream.id
                                    }
                                } else {
                                    plottingState.selectedStreams.append(stream)
                                }
                            } label: {
                                if plottingState.selectedStreams.contains(stream) {
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
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Deselect all") {
                    plottingState.selectedStreams = []
                }
                
                Button("Select all") {
                    plottingState.selectedStreams = doc.contents.streams
                }
            }
        }
    }
    #endif
}
