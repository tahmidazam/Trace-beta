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
                        Stepper("\(plottingState.windowSize)", value: $plottingState.windowSize, in: 50...500, step: 50)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } label: {
                        Text("Plotting window size")
                        Text("The number of samples plotted")
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
}
