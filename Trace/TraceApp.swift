//
//  TraceApp.swift
//  Trace
//
//  Created by Tahmid Azam on 05/07/2022.
//

import SwiftUI

@main
struct TraceApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TraceDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
