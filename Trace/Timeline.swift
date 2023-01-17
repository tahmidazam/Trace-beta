//
//  Timeline.swift
//  Trace
//
//  Created by Tahmid Azam on 16/01/2023.
//

import Foundation
import SwiftUI

fileprivate let labelColor = Color.gray
fileprivate let tintColor = Color.primary


struct Timeline: View {
    @Binding var doc: TraceDocument
    @ObservedObject var plottingState: PlottingState
    
    
    var sampleCount: Int {
        return doc.contents.sampleCount ?? 0
    }
    var progress: CGFloat {
        return CGFloat(plottingState.windowStartIndex) / CGFloat(sampleCount - plottingState.windowSize - 1)
    }
    var windowProportion: CGFloat {
        return CGFloat(plottingState.windowSize) / CGFloat(sampleCount - plottingState.windowSize - 1)
    }
    var slidablePropotion: CGFloat {
        return CGFloat(sampleCount - plottingState.windowSize) / CGFloat(sampleCount - 1)
    }
    
    @State var progressState: CGFloat = 0
    
    enum DragState {
        case inactive
        case pressing
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive, .pressing:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .pressing, .dragging:
                return true
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive, .pressing:
                return false
            case .dragging:
                return true
            }
        }
    }
    @GestureState var dragState = DragState.inactive
    
    var scale: CGFloat {
        dragState.isActive ? 1.3 : 1.0
    }
    
    let minimumLongPressDuration = 0.01
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.accentColor)
                    .opacity(dragState.isActive ? 0.6 : 0.3)
                    .frame(width: size.width * windowProportion)
                    .offset(x: size.width * slidablePropotion * progress)
                
                Canvas { context, size in
                    #if os(macOS)
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(.quaternaryLabelColor)))
                    #else
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(.quaternaryLabel)))
                    #endif
                    
                    for event in doc.contents.events.filter({ event in
                        plottingState.selectedEventTypes.contains(event.type)
                    }) {
                        let timeProportion = CGFloat(event.sampleIndex + 1) / CGFloat(sampleCount)
                        
                        let x = size.width * timeProportion
                        
                        let linePath: Path = Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        
                        context.stroke(linePath, with: .color(.red), lineWidth: plottingState.lineWidth)
                        
                        if plottingState.showEpochs {
                            let epochEnd = size.width * (CGFloat(doc.contents.epochLength + event.sampleIndex + 1) / CGFloat(sampleCount))
                            
                            let epochPath = Path { path in
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: epochEnd, y: 0))
                                path.addLine(to: CGPoint(x: epochEnd, y: size.height))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                            }
                            
                            let eventEndPath = Path { path in
                                path.move(to: CGPoint(x: epochEnd, y: 0))
                                path.addLine(to: CGPoint(x: epochEnd, y: size.height))
                            }
                            
                            context.fill(epochPath, with: .color(.red.opacity(0.1)))
                            context.stroke(eventEndPath, with: .color(.red), style: StrokeStyle(lineWidth: plottingState.lineWidth, dash: [2]))
                        }
                    }
                }
                
                
            }
            .mask(Capsule())
            .task {
                progressState = progress
            }
            .gesture(
                LongPressGesture(minimumDuration: minimumLongPressDuration)
                    .sequenced(before: DragGesture())
                    .updating($dragState) { value, state, transaction in
                        switch value {
                        case .first(true):
                            state = .pressing
                        case .second(true, let drag):
                            state = .dragging(translation: drag?.translation ?? .zero)
                        default:
                            state = .inactive
                        }
                    }
                    .onChanged { _ in
                        withAnimation {
                            plottingState.windowStartIndex = Int(CGFloat(sampleCount - plottingState.windowSize - 1) * max(0.0, min(1.0, progressState + dragState.translation.width / size.width)))
                        }
                    }
                    .onEnded { value in
                        guard case .second(true, let drag?) = value else { return }
                        progressState = max(0.0, min(1.0, progressState + drag.translation.width / size.width))
                        withAnimation {
                            plottingState.windowStartIndex = Int(CGFloat(sampleCount - plottingState.windowSize - 1) * progressState)
                        }
                    }
            )
            .scaleEffect(y: scale)
            .animation(.easeInOut, value: scale)
        }
        .frame(height: 10)
        .onChange(of: plottingState.windowStartIndex) { newValue in
            if !dragState.isActive {
                progressState = CGFloat(newValue) / CGFloat(sampleCount - plottingState.windowSize - 1)
            }
        }
    }
}
