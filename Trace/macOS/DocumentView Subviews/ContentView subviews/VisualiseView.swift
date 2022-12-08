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
    
    var body: some View {
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
        .toolbar {
            ToolbarItemGroup {
                stepBackward10Button
                stepBackward1Button
                stepForward1Button
                stepForward10Button
            }
        }
    }
    
    var electrodeLabels: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(doc.contents.streams) { stream in
                    if let location = stream.electrode.location?.cgPoint(in: proxy.size) {
                        VStack {
                            Text(stream.electrode.symbol).font(.headline)
                            Text("\(stream.samples[index].format())").font(.subheadline)
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
