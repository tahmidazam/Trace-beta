//
//  VisualiseView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/11/2022.
//

import SwiftUI

struct VisualiseView: View {
    @Binding var doc: TraceDocument
    
    @State var index: Int = 0
    
    var progress: Double {
        guard let sampleCount = doc.contents.sampleCount else {
            return 0.0
        }
        
        return (Double(index) / Double(sampleCount))
    }
    
    var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color(.quaternaryLabelColor))
                
                Rectangle()
                    .foregroundColor(.accentColor)
                    .frame(width: proxy.size.width * progress)
            }
//            .gesture(DragGesture().onChanged({ value in
//                guard let sampleCount = doc.contents.sampleCount else {
//                    return
//                }
//
//                let proportionDragged = (value.translation.width / proxy.size.width) / 10
//
//                let indexDelta = Int(round(proportionDragged * Double(sampleCount)))
//
//                guard (0..<sampleCount).contains(index + indexDelta) else {
//                    return
//                }
//
//                index = index + indexDelta
//            }))
        }
        .mask(Capsule())
        .frame(height: 10)
    }
    
    var body: some View {
        VStack {
            ZStack {
                Canvas { context, size in
                    for stream in doc.contents.streams {
                        if let sector = stream.electrode.sector(in: size),
                           let potentialRange = doc.contents.potentialRange,
                           let color = stream.color(at: index, globalPotentialRange: potentialRange) {
                            context.fill(sector, with: .color(color))
                        }
                    }
                }
                
                electrodeLabels
            }
            
            VStack {
                HStack {
                    Text(doc.contents.time(at: index).format())
                    
                    progressBar
                    
                    if let duration = doc.contents.duration {
                        Text(duration.format())
                    }
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                
                HStack {
                    if let sampleCount = doc.contents.sampleCount {
                        Text("Sample \(index + 1) of \(sampleCount)")
                    }
                }
                
                HStack {
                    stepBackward10Button
                        .keyboardShortcut(.leftArrow)
                        .buttonStyle(.borderless)
                    
                    stepBackward1Button
                        .keyboardShortcut(.leftArrow, modifiers: [])
                        .buttonStyle(.borderless)
                    
                    stepForward1Button
                        .keyboardShortcut(.rightArrow, modifiers: [])
                        .buttonStyle(.borderless)
                    
                    stepForward10Button
                        .keyboardShortcut(.rightArrow)
                        .buttonStyle(.borderless)
                }
            }
            .frame(maxWidth: 500)
            .padding()
        }
//        .toolbar {
//            ToolbarItemGroup {
//                stepBackward10Button
//                stepBackward1Button
//                stepForward1Button
//                stepForward10Button
//            }
//        }
    }
    
    var electrodeLabels: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(doc.contents.streams) { stream in
                    if let location = stream.electrode.location?.cgPoint(in: proxy.size) {
                        VStack {
                            Text(stream.electrode.symbol).font(.headline)
                            Text("\(stream.samples[index].format())").font(.system(.caption, design:.monospaced))
                        }
                        .position(x: location.x, y: location.y)
                    }
                }
            }
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
}

struct VisualiseView_Previews: PreviewProvider {
    static var previews: some View {
        VisualiseView(doc: .constant(TraceDocument()))
    }
}
