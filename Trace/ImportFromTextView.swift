//
//  ImportFromTextView.swift
//  Trace
//
//  Created by Tahmid Azam on 05/07/2022.
//

import SwiftUI

struct ImportFromTextView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var stream: Stream
    @State var importText: String = "-1.1\n-1.0\n-0.9"
    
    var body: some View {
        NavigationStack {
            TextEditor(text: $importText)
                .onChange(of: importText, perform: { newValue in
                    importText = newValue.filter{ $0 != " " }
                })
                .padding()
                .navigationTitle("Import from text")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: cancel)
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import", action: importToStream)
                            .disabled(disabled)
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        Label {
                            Text("\(disabled ? "Invalid text entry" : "\((stringToDoubleArray(string: importText) ?? []).count) sample\((stringToDoubleArray(string: importText) ?? []).count == 1 ? "" : "s") found")")
                                .font(.headline)
                        } icon: {
                            Image(systemName: disabled ? "xmark.circle.fill" : "checkmark.circle.fill")
                                .foregroundColor(disabled ? .red : .green)
                        }
                        .labelStyle(.titleAndIcon)
                    }
                }
        }
    }
    
    var disabled: Bool {
        stringToDoubleArray(string: importText) == nil
    }
    
    func cancel() {
        presentationMode.wrappedValue.dismiss()
    }
    func importToStream() {
        stream.samples = stringToDoubleArray(string: importText)!
        
        presentationMode.wrappedValue.dismiss()
    }
    func stringToDoubleArray(string: String) -> [Double]? {
        let components = string.components(separatedBy: .whitespacesAndNewlines)
        let doubleArray = components.compactMap { sample in
            return Double(sample)
        }
        
        guard components.count == doubleArray.count else {
            return nil
        }
        
        return doubleArray
    }
}

struct ImportFromTextView_Previews: PreviewProvider {
    static var previews: some View {
        ImportFromTextView(stream: .constant(Stream(electrode: .init(prefix: .parietal, suffix: 0), samples: [])))
    }
}
