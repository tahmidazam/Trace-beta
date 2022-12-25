//
//  StudyView.swift
//  Trace
//
//  Created by Tahmid Azam on 11/12/2022.
//

import SwiftUI

struct StudyView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var doc: TraceDocument
    
    @State var text: String = ""
    
    var body: some View {
        List {
            Section("Subject") {
                LabeledContent {
                    TextField("Add subject name", text: $doc.contents.subject)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 300)
                } label: {
                    Text("Name")
                    Text("The name of the subject involved in the EEG recording")
                }
                
                LabeledContent {
                    TextField("Add subject information", text: $doc.contents.info)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 300)
                } label: {
                    Text("Description")
                    Text("Additional information carried as metadata in this Trace document")
                }
            }
            
            Section("Sampling") {
                LabeledContent {
                    HStack {
                        Text("\(doc.contents.sampleRate.format()) Hz")
                        Stepper("", value: $doc.contents.sampleRate, in: 1...2000)
                            .labelsHidden()
                    }
                } label: {
                    Text("Sample rate")
                    Text("The number of times scalp potentials are sampled every second")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView(doc: .constant(TraceDocument()))
    }
}
