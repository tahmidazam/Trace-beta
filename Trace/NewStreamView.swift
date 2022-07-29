//
//  NewStreamView.swift
//  Trace
//
//  Created by Tahmid Azam on 05/07/2022.
//

import SwiftUI
import Charts

struct NewStreamView: View {
    @Binding var document: TraceDocument
    @State var stream = Stream(electrode: .init(prefix: .parietal, suffix: 0), samples: [])
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var presentImportFromTextView = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Electrode information") {
                    Picker("Prefix", selection: $stream.electrode.prefix) {
                        ForEach(Electrode.Prefix.allCases, id: \.self) { prefix in
                            Text(prefix.rawValue).tag(prefix)
                        }
                    }
                    Picker("Suffix", selection: $stream.electrode.suffix) {
                        ForEach(0...8, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                }
                
                Section(numberOfSamplesText) {
                    if !stream.samples.isEmpty {
//                        SamplesChart(document: $document, samples: stream.samples)
//                            .frame(height: 200)
                        
                        NavigationLink("All samples") {
                            List {
                                Section(numberOfSamplesText) {
                                    ForEach(stream.samples, id: \.self) { sample in
                                        Text("\(sample)")
                                    }
                                }
                            }
                            .navigationTitle("All samples")
                        }
                    }
                    Button("Import from text", action: importFromText)
                }
            }
            .navigationTitle("New stream")
            .sheet(isPresented: $presentImportFromTextView) {
                ImportFromTextView(stream: $stream)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addStream)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    
    func importFromText() {
        presentImportFromTextView.toggle()
    }
    
    var numberOfSamplesText: String {
        "\(stream.samples.count) sample\(stream.samples.count == 1 ? "" : "s")"
    }
    
    func cancel() {
        presentationMode.wrappedValue.dismiss()
    }
    func addStream() {
        document.contents.streams.append(stream)
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct NewStreamView_Previews: PreviewProvider {
    static var previews: some View {
        NewStreamView(document: .constant(TraceDocument()))
    }
}
