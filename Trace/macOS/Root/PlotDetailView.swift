//
//  PlotDetailView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct PlotDetailView: View {
    @Binding var doc: TraceDocument
    @Binding var visualisation: RootView.Visualisation
    @Binding var plottingWindowSampleSize: Int
    @Binding var showElectrodeLabels: Bool
    @Binding var showElectrodePotentials: Bool
    @Binding var lineWidth: CGFloat
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0.0) {
                LabeledContent {
                    Picker("", selection: $visualisation) {
                        Label("Stacked plot", systemImage: "chart.bar.doc.horizontal")
                            .tag(RootView.Visualisation.stackedPlot)
                        
                        Label("Scalp map", systemImage: "circle.dashed")
                            .tag(RootView.Visualisation.scalpMap)
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
                
                switch visualisation {
                case .stackedPlot:
                    LabeledContent {
                        Stepper("\(plottingWindowSampleSize)", value: $plottingWindowSampleSize, in: 50...500, step: 50)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } label: {
                        Text("Plotting window size")
                        Text("The number of samples plotted")
                    }
                    .padding(.vertical)
                    
                    Divider()
                    
                    LabeledContent {
                        Stepper("\(lineWidth)", value: $lineWidth, in: 1.0...5.0, step: 0.5)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } label: {
                        Text("Plot line width")
                    }
                    .padding(.vertical)
                    
                    Divider()
                case .scalpMap:
                    VStack {
                        Toggle(isOn: $showElectrodeLabels) {
                            Text("Show electrode labels")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $showElectrodePotentials) {
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
