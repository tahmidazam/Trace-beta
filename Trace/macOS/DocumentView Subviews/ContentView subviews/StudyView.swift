//
//  StudyView.swift
//  Trace
//
//  Created by Tahmid Azam on 11/12/2022.
//

import SwiftUI

struct StudyView: View {
    @Binding var doc: TraceDocument
    
    @State var text: String = ""
    
    var body: some View {
        
        ScrollView {
            
            VStack {
                GroupBox {
                    VStack(spacing: 0.0) {
                        LabeledContent {
                            TextField("Add subject name", text: $doc.contents.subject)
                                .frame(width: 300)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } label: {
                            Text("Name")
                        }
                        .padding(5)
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        LabeledContent {
                            TextField("Add subject information", text: $doc.contents.info)
                                .frame(width: 300)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } label: {
                            Text("Description")
                        }
                        .padding(5)
                    }
                } label: {
                    Text("Subject")
                        .font(.headline)
                        .padding(.bottom, 5)
                }
                
                GroupBox {
                    VStack {
                        LabeledContent {
                            Stepper("\(doc.contents.sampleRate.format()) Hz", value: $doc.contents.sampleRate, in: 1...1000)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } label: {
                            Text("Sample rate")
                            Text("The number of times scalp potentials are sampled every second.")
                        }
                        .padding(5)
                    }
                } label: {
                    Text("Sampling")
                        .font(.headline)
                        .padding(.bottom, 5)
                }
                .padding(.top)

                GroupBox {
                    VStack {
                        LabeledContent {
                            Stepper("\(doc.contents.epochLength) samples", value: $doc.contents.sampleRate, in: 1...1_000_000)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } label: {
                            Text("Epoch length")
                            Text("Number of samples included in an epoch after the event index.")
                        }
                        .padding(5)
                    }
                } label: {
                    Text("Epoching")
                        .font(.headline)
                        .padding(.bottom, 5)
                }
                .padding(.top)
            }
            .padding()
        }
    }
}

struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView(doc: .constant(TraceDocument()))
    }
}
