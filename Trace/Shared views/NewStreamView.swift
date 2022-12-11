//
//  NewStreamView.swift
//  Trace
//
//  Created by Tahmid Azam on 05/07/2022.
//
//  Copyright (C) 2022 Tahmid Azam
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

import SwiftUI
import Charts

#if os(iOS)
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
#else

struct NewStreamView: View {
    
    @State var stream = Stream(electrode: .init(prefix: .parietal, suffix: 0), samples: [])
    
    var body: some View {
        NavigationSplitView {
            GeometryReader { proxy in
                ZStack {
                    ForEach(Electrode.Prefix.allCases) { prefix_ in
                        ForEach(prefix_.validSuffixes, id: \.self) { suffix in
                            let electrode = Electrode(prefix: prefix_, suffix: suffix)
                            
                            if let sector = electrode.sector(in: proxy.size),
                               let location = electrode.location?.cgPoint(in: proxy.size) {
                                
                                if electrode == stream.electrode {
                                    sector.fill(Color.accentColor)
                                    
                                } else {
                                    sector.fill(Color(.unemphasizedSelectedContentBackgroundColor))
                                    
                                }
                                Text(electrode.symbol)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .position(x: location.x, y: location.y)
                            }
                        }
                    }
                }
            }
            .padding()
            .padding()
            .frame(minWidth: 300)
        } detail: {
            VStack(spacing: 0.0) {
                VStack {
                    GroupBox {
                        prefixPicker
                        
                        Divider()
                        
                        suffixPicker
                    }

                }
                .padding()
                
                Spacer()
                
                Divider()
                
                bottomBar
            }
        }

    }
    
    var bottomBar: some View {
        HStack {
            Button("Cancel") {
                
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button("Add stream") {
                
            }
            .keyboardShortcut(.defaultAction)

        }
        .padding()
        
    }
    
    var prefixPicker: some View {
        LabeledContent {
            Picker("Prefix", selection: $stream.electrode.prefix) {
                ForEach(Electrode.Prefix.allCases, id: \.self) { prefix in
                    Text(prefix.rawValue).tag(prefix)
                }
            }
            .labelsHidden()
            .frame(width: 100)
            .frame(maxWidth: .infinity, alignment: .trailing)
        } label: {
            Text("Prefix")
        }
    }
    
    var suffixPicker: some View {
        LabeledContent {
            Picker("Suffix", selection: $stream.electrode.suffix) {
                ForEach(0...8, id: \.self) { i in
                    Text("\(i)").tag(i)
                }
            }
            .labelsHidden()
            .frame(width: 100)
            .frame(maxWidth: .infinity, alignment: .trailing)
        } label: {
            Text("Suffix")
        }
    }
}

struct NewStreamView_Previews: PreviewProvider {
    static var previews: some View {
        NewStreamView()
    }
}
#endif

