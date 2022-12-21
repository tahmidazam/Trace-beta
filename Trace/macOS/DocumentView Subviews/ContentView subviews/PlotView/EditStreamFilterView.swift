//
//  EditStreamFilterView.swift
//  Trace
//
//  Created by Tahmid Azam on 20/12/2022.
//

import SwiftUI

struct EditStreamFilterView: View {
    @Binding var doc: TraceDocument
    @Binding var selectedStreams: [Stream]
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack(spacing: 0.0) {
            VStack(alignment: .leading) {
                Text("Edit stream filter")
                    .font(.headline)
                
                Text("Select which streams to plot.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Divider()
            
            List {
                ForEach(doc.contents.streams) { stream in
                    HStack {
                        Text(stream.electrode.symbol)
                        
                        Spacer()
                        
                        Group {
                            if selectedStreams.contains(stream) {
                                Button("Remove") {
                                    selectedStreams.removeAll { stream_ in
                                        stream_ == stream
                                    }
                                }
                                .buttonStyle(.borderless)
                            } else {
                                Button("Add") {
                                    selectedStreams.append(stream)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                Button("Remove all") {
                    selectedStreams = []
                }
                
                Button("Add all") {
                    selectedStreams = doc.contents.streams
                }
                
                Text("\(selectedStreams.count) of \(doc.contents.streams.count) selected.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done", action: close)
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
            .frame(minWidth: 500, minHeight: 500)
    }
    
    func close() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditStreamFilterView_Previews: PreviewProvider {
    static var previews: some View {
        EditStreamFilterView(doc: .constant(TraceDocument()), selectedStreams: .constant([]))
    }
}
