//
//  ContentView.swift
//  Trace
//
//  Created by Tahmid Azam on 05/07/2022.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: TraceDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(TraceDocument()))
    }
}
