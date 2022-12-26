//
//  EventsDetailView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct EventsDetailView: View {
    @Binding var doc: TraceDocument
    @Binding var selectedEventTypes: [String]
    @Binding var showEpochs: Bool
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0.0) {
                Toggle(isOn: $showEpochs) {
                    Text("Show epochs")
                    Text("Color the epoch window along with event stamps")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
                
                Divider()
                
                LabeledContent {
                    Stepper("\(doc.contents.epochLength)", value: $doc.contents.epochLength, in: 10...500, step: 10)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("Epoch length")
                    Text("The number of samples that make up an epoch")
                }
                .padding(.vertical)

                
                Divider()
                
                VStack(spacing: 0.0) {
                    LabeledContent {
                        EmptyView()
                    } label: {
                        Text("Event types")
                        Text("Select event types to plot")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                    
                    VStack {
                        ForEach(doc.contents.eventTypes, id: \.self) { eventType in
                            HStack {
                                Button {
                                    if selectedEventTypes.contains(eventType) {
                                        selectedEventTypes.removeAll { eventType_ in
                                            eventType_ == eventType
                                        }
                                    } else {
                                        selectedEventTypes.append(eventType)
                                    }
                                } label: {
                                    if selectedEventTypes.contains(eventType) {
                                        Image(systemName: "circle.inset.filled")
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.borderless)
                                .padding(.trailing)
                                
                                LabeledContent {
                                    Text("\(doc.contents.events.filter({ event in event.type == eventType }).count)")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                } label: {
                                    Text(eventType)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Button("Deselect all") {
                            selectedEventTypes = []
                        }
                        
                        Button("Select all") {
                            selectedEventTypes = doc.contents.eventTypes
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                }
                .padding(.vertical)

                Divider()
            }
            .padding()
        }
    }
}
