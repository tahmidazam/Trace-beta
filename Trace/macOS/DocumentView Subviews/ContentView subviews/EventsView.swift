//
//  EventsView.swift
//  Trace
//
//  Created by Tahmid Azam on 10/12/2022.
//

import SwiftUI

struct EventsView: View {
    @Binding var doc: TraceDocument
    
    @State var keys: Set<String> = []
    
    var body: some View {
        EmptyView()
    }
}
