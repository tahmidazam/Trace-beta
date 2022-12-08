//
//  ScalpMapView.swift
//  Trace
//
//  Created by Tahmid Azam on 29/07/2022.
//
//  Copyright (C) 2022 Tahmid Azam
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

import SwiftUI

#if os(iOS)
struct ScalpMapView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var doc: TraceDocument
    
    @State var index = 0
    @State var playing = false
    @State var timeProportion: Double = 0.0
    
    @State var selectedStreams: [Stream] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                visualisation
                
                VStack {
                    Text(time)
                        .font(.headline)
                    
                    if let sampleInfo {
                        Text(sampleInfo)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Slider(value: $timeProportion, in: 0...1)
                    .onChange(of: timeProportion) { newValue in
                        if let sampleCount = doc.contents.sampleCount {
                            index = Int(Double(sampleCount - 1) * newValue)
                        }
                    }
                    .onChange(of: index) { newValue in
                        if let sampleCount = doc.contents.sampleCount {
                            timeProportion = Double(index + 1) / Double(sampleCount)
                        }
                    }
                    .disabled(playing)
            }
            .padding()
            .navigationTitle("Rendering \(selectedStreams.count) of \(doc.contents.streams.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction, content: { doneButton })
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    
                    stepBackward10Button
                    stepBackward1Button
                    playButton
                    stepForward1Button
                    stepForward10Button
                    
                    Spacer()
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    streamSelector
                        .onChange(of: selectedStreams) { newValue in
                            selectedStreams = newValue.filter { stream in
                                stream.electrode.location != nil
                            }
                        }
                }
            }
            .task {
                selectedStreams = doc.contents.streams
            }
        }
    }
    
    var time: String {
        "\(doc.contents.time(at: index).format()) s of \(doc.contents.duration?.format() ?? "") s"
    }
    var sampleInfo: String? {
        guard let count = doc.contents.streams.first?.samples.count else {
            return nil
        }
        
        return "Sample \(index + 1) of \(count)"
    }
    var visualisation: some View {
        TraceDocumentContents.Visualisation(
            streams: selectedStreams,
            potentialRange: doc.contents.potentialRange,
            index: index
        )
    }
    var doneButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Done")
        }
    }
    var stepBackward1Button: some View {
        Button(action: {
            index -= 1
        }) {
            Image(systemName: "backward.frame.fill")
        }.disabled(index - 1 < 0)
    }
    var stepBackward10Button: some View {
        Button(action: {
            index -= 10
        }) {
            Image(systemName: "gobackward.10")
        }.disabled(index - 10 < 0)
    }
    var stepForward1Button: some View {
        Button(action: {
            index += 1
        }) {
            Image(systemName: "forward.frame.fill")
        }
        .disabled(index + 1 > doc.contents.sampleCount ?? 0)
    }
    var stepForward10Button: some View {
        Button(action: {
            index += 10
        }) {
            Image(systemName: "goforward.10")
        }
        .disabled(index + 10 > doc.contents.sampleCount ?? 0)
    }
    var playButton: some View {
        Button(action: {
            if playing {
                playing = false
            } else {
                playing = true
                step()
            }
        }) {
            ZStack {
                Image(systemName: "play.fill")
                    .opacity(playing ? 0 : 1)
                
                Image(systemName: "pause.fill")
                    .opacity(playing ? 1 : 0)
            }
        }
    }
    
    func step() {
        DispatchQueue.main.asyncAfter(deadline: .now() + (1 / doc.contents.sampleRate)) {
            let stepSize = 1
            if index + stepSize <= doc.contents.sampleCount ?? 0 {
                index += stepSize
            } else {
                index = 0
            }
            
            if playing {
                step()
            }
        }
    }
    var streamSelector: some View {
        Menu {
            Section {
                Button("Select all") { selectedStreams = doc.contents.streams }
                Button("Deselect all") { selectedStreams = [] }
            }
            
            ForEach(doc.contents.prefixes, id: \.self) { pre in
                Section {
                    let streams = doc.contents.streams.filter { stream in
                        return stream.electrode.prefix == pre
                    }.sorted { a, b in
                        a.electrode.suffix < b.electrode.suffix
                    }
                    
                    ForEach(streams, id: \.self) { stream in
                        Button {
                            if selectedStreams.contains(stream) {
                                selectedStreams.removeAll(where: { $0.id == stream.id })
                            } else {
                                selectedStreams.append(stream)
                            }
                        } label: {
                            Label {
                                Text(stream.electrode.symbol)
                            } icon: {
                                if selectedStreams.contains(stream) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            Label("Select streams", systemImage: "list.bullet")
        }
    }
}

struct ScalpMapView_Previews: PreviewProvider {
    static var previews: some View {
        ScalpMapView(doc: .constant(TraceDocument()))
    }
}
#endif
