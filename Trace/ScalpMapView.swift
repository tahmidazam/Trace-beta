//
//  ScalpMapView.swift
//  Trace
//
//  Created by Tahmid Azam on 29/07/2022.
//

import SwiftUI

struct ScalpMapView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var doc: TraceDocument
    
    @State var index = 0
    @State var playing = false
    @State var timer: Timer? = nil
    @State var timeProportion: Double = 0.0
    
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
            }
            .padding()
            .navigationTitle("Scalp Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Stream.self, destination: { stream in StreamDetailView(doc: $doc, stream: stream) })
            .toolbar(content: { toolbar })
        }
    }
    
    var streamsWithLocations: [Stream] {
        doc.contents.streams.filter { stream in
            Electrode.location(from: stream.electrode) != nil
        }
    }
    
    var time: String {
        "\(String(format: "%.3f", doc.contents.time(at: index)))s"
    }
    var sampleInfo: String? {
        guard let count = doc.contents.streams.first?.samples.count else {
            return nil
        }
        
        return "Sample \(index + 1) of \(count)"
    }
    var visualisation: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                for stream in doc.contents.streams {
                    if let sector = Electrode.sector(stream: stream, size: proxy.size),
                       let min = doc.contents.minPotential,
                       let max = doc.contents.maxPotential {
                        context.fill(sector, with: .color(Stream.scalpMapColor(value: stream.samples[index], min: min, max: max)))
                    }
                }
            }
            
            ForEach(streamsWithLocations) { stream in
                NavigationLink(value: stream) {
                    Text(stream.electrode.symbol)
                        .font(.caption.bold())
                        .foregroundStyle(.ultraThickMaterial)
                }
                .position(electrodePoint(stream: stream, size: proxy.size)!)
            }
        }
    }
    var toolbar: some ToolbarContent {
        Group {
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
        }
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
                timer?.invalidate()
                timer = nil
            } else {
                playing = true
                
                timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { tempTimer in
                    let step = 1
                    if index + step <= doc.contents.sampleCount ?? 0 {
                        index += step
                    } else {
                        index = 0
                    }
                })
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
    
    func electrodePoint(stream: Stream, size: CGSize) -> CGPoint? {
        guard let location = Electrode.location(from: stream.electrode) else {
            return nil
        }
        
        return location.cgPoint(in: size)
    }
}

struct ScalpMapView_Previews: PreviewProvider {
    static var previews: some View {
        ScalpMapView(doc: .constant(TraceDocument()))
    }
}
