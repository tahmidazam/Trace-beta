//
//  PlotDetailView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct PlotDetailView: View {
    @Binding var doc: TraceDocument
    @ObservedObject var plottingState: PlottingState
    
    #if os(macOS)
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0.0) {
                LabeledContent {
                    Picker("", selection: $plottingState.visualisation) {
                        Label("Stacked plot", systemImage: "chart.bar.doc.horizontal")
                            .tag(PlottingState.Visualisation.stackedPlot)
                        
                        Label("Scalp map", systemImage: "circle.dashed")
                            .tag(PlottingState.Visualisation.scalpMap)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .buttonStyle(.borderless)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } label: {
                    Text("Plot type")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom)
                
                Divider()
                
                switch plottingState.visualisation {
                case .stackedPlot:
                    LabeledContent {
                        Stepper("\(plottingState.windowSize)", value: $plottingState.windowSize, in: 100...20_000, step: 1000)
                            .fixedSize(horizontal: true, vertical: false)
                    } label: {
                        Text("Window size")
                        Text("The number of samples plotted in the viewing window")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical)
                    
                    Divider()
                    
                    LabeledContent {
                        Stepper("\(plottingState.stepSize)", value: $plottingState.stepSize, in: 1...200, step: plottingState.stepSize == 1 ? 9 : 10)
                            .fixedSize(horizontal: true, vertical: false)
                    } label: {
                        Text("Step size")
                        Text("The number of samples to step with the left or right arrow keys")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical)
                    
                    Divider()
                    
                    LabeledContent {
                        Stepper("\(plottingState.pointsPerCGPoint)", value: $plottingState.pointsPerCGPoint, in: 1...200, step: 1)
                            .fixedSize(horizontal: true, vertical: false)
                    } label: {
                        Text("Resolution")
                        Text("The number of samples plot per pixel")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical)
                    
                    Divider()
                    
                    LabeledContent {
                        Stepper("\(plottingState.lineWidth)", value: $plottingState.lineWidth, in: 1.0...5.0, step: 0.5)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } label: {
                        Text("Plot line width")
                    }
                    .padding(.vertical)
                    
                    Divider()
                case .scalpMap:
                    VStack {
                        Toggle(isOn: $plottingState.showElectrodeLabels) {
                            Text("Show electrode labels")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $plottingState.showElectrodePotentials) {
                            Text("Show electrode potentials")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical)
                    
                    Divider()
                }
            }
            .padding()
        }
    }
    #else
    var body: some View {
        List {
            Section {
                Picker("Plot type", selection: $plottingState.visualisation) {
                    Label("Stacked plot", systemImage: "chart.bar.doc.horizontal")
                        .tag(PlottingState.Visualisation.stackedPlot)
                    
                    Label("Scalp map", systemImage: "circle.dashed")
                        .tag(PlottingState.Visualisation.scalpMap)
                }
                .pickerStyle(.menu)
            }
            
            Section {
                switch plottingState.visualisation {
                case .stackedPlot:
                    Stepper(value: $plottingState.windowSize, in: 50...500, step: 50) {
                        Text("Window size: \(plottingState.windowSize)")
                        Text("The number of samples plotted")
                    }
                    
                    Stepper("Line width: \(plottingState.lineWidth)", value: $plottingState.lineWidth, in: 1.0...5.0, step: 0.5)
                case .scalpMap:
                    Toggle(isOn: $plottingState.showElectrodeLabels) {
                        Text("Show electrode labels")
                    }
                    
                    Toggle(isOn: $plottingState.showElectrodePotentials) {
                        Text("Show electrode potentials")
                    }
                }
            }
        }
    }
    #endif
}
