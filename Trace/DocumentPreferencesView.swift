//
//  DocumentPreferencesView.swift
//  Trace
//
//  Created by Tahmid Azam on 29/07/2022.
//

import SwiftUI

struct DocumentPreferencesView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var doc: TraceDocument
    
    var body: some View {
        NavigationStack {
            List {
                Section("Subject") {
                    HStack {
                        Text("Name")
                        
                        Spacer()
                        
                        Text(doc.contents.subject ?? "No data")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Info")
                        
                        Text(doc.contents.subject ?? "No data")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Timing") {
                    HStack {
                        Text("Sample rate")
                        
                        Spacer()
                        
                        Text("\(doc.contents.sampleRate.format()) Hz")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Document Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: { toolbar })
        }
    }
    
    var toolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .confirmationAction, content: { doneButton })
        }
    }
    
    var doneButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Done")
        }
    }
}

struct DocumentPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentPreferencesView(doc: .constant(TraceDocument()))
    }
}
