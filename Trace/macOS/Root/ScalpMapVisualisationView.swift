//
//  ScalpMapVisualisationView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct ScalpMapVisualisationView: View {
    @Binding var doc: TraceDocument
    @Binding var selectedStreams: [Stream]
    @Binding var scalpMapSampleIndexToDisplay: Int
    @Binding var showElectrodeLabels: Bool
    @Binding var showElectrodePotentials: Bool
    @Binding var showEpochs: Bool
    @Binding var selectedEventTypes: [String]
    @Binding var lineWidth: CGFloat
    @Binding var plottingWindowSampleSize: Int
    @Binding var plottingWindowFirstSampleIndex: Int
    @Binding var visualisation: RootView.Visualisation
    
    var body: some View {
        VStack(spacing: 0.0) {
            ZStack {
                Canvas { context, size in
                    for stream in selectedStreams {
                        if let sector = stream.electrode.sector(in: size),
                           let potentialRange = doc.contents.potentialRange,
                           let color = stream.color(at: scalpMapSampleIndexToDisplay, globalPotentialRange: potentialRange) {
                            context.fill(sector, with: .color(color))
                        }
                    }
                }
                
                electrodeLabels
            }
            .padding(50)
            
            Divider()
            
            VStack {
                TimelineView(doc: $doc, selectedEventTypes: $selectedEventTypes, lineWidth: $lineWidth, showEpochs: $showEpochs, plottingWindowSampleSize: $plottingWindowSampleSize, plottingWindowFirstSampleIndex: $plottingWindowFirstSampleIndex, visualisation: $visualisation, scalpMapSampleIndexToDisplay: $scalpMapSampleIndexToDisplay)

                
                scalpMapBottomBar
            }
            .padding()
        }
    }
    var electrodeLabels: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(selectedStreams) { stream in
                    if let location = stream.electrode.location?.cgPoint(in: proxy.size) {
                        VStack {
                            if showElectrodeLabels {
                                Text(stream.electrode.symbol).font(.headline)
                            }
                            if showElectrodePotentials {
                                Text("\(stream.samples[scalpMapSampleIndexToDisplay].format())").font(.system(.caption, design:.monospaced))
                            }
                        }
                        .position(x: location.x, y: location.y)
                    }
                }
            }
        }
    }
    var scalpMapBottomBar: some View {
        HStack {
            stepBackward10Button
                .keyboardShortcut(.leftArrow)
                .buttonStyle(.borderless)
            
            stepBackward1Button
                .keyboardShortcut(.leftArrow, modifiers: [])
                .buttonStyle(.borderless)
            
            Spacer()
            
            VStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("#")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(scalpMapSampleIndexToDisplay + 1)")
                        .font(.system(.title2, design: .monospaced))
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 0.0) {
                    Text("\(doc.contents.time(at: scalpMapSampleIndexToDisplay).format())")
                        .font(.system(.body, design: .monospaced))
                    
                    Text(" s")
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            stepForward1Button
                .keyboardShortcut(.rightArrow, modifiers: [])
                .buttonStyle(.borderless)
            
            stepForward10Button
                .keyboardShortcut(.rightArrow)
                .buttonStyle(.borderless)
        }
    }
    
    var stepBackward1Button: some View {
        Button(action: {
            scalpMapSampleIndexToDisplay -= 1
        }) {
            Image(systemName: "backward.frame.fill")
        }.disabled(scalpMapSampleIndexToDisplay - 1 < 0)
    }
    var stepBackward10Button: some View {
        Button(action: {
            scalpMapSampleIndexToDisplay -= 10
        }) {
            Image(systemName: "gobackward.10")
        }.disabled(scalpMapSampleIndexToDisplay - 10 < 0)
    }
    var stepForward1Button: some View {
        Button(action: {
            scalpMapSampleIndexToDisplay += 1
        }) {
            Image(systemName: "forward.frame.fill")
        }
        .disabled(scalpMapSampleIndexToDisplay + 1 > doc.contents.sampleCount ?? 0)
    }
    var stepForward10Button: some View {
        Button(action: {
            scalpMapSampleIndexToDisplay += 10
        }) {
            Image(systemName: "goforward.10")
        }
        .disabled(scalpMapSampleIndexToDisplay + 10 > doc.contents.sampleCount ?? 0)
    }
}
