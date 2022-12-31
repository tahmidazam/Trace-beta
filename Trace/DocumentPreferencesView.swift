//
//  DocumentPreferencesView.swift
//  Trace
//
//  Created by Tahmid Azam on 29/07/2022.
//
//  Copyright (C) 2022 Tahmid Azam
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.
import SwiftUI


#if os(iOS)
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
                        
                        Text(doc.contents.subject)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Info")
                        
                        Text(doc.contents.subject)
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
#endif
