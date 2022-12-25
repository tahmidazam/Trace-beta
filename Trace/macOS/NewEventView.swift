//
//  NewEventView.swift
//  Trace
//
//  Created by Tahmid Azam on 18/12/2022.
//

import SwiftUI

struct NewEventView: View {
    @Binding var doc: TraceDocument
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var event: String = ""
    @State var eventType: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("New event")
                .font(.headline)
            
            Text("Mark a sample/timestamp with an event to enable epoching.")
                .fixedSize(horizontal: false, vertical: true)
            
            GroupBox {
                VStack(spacing: 0.0) {
                    HStack {
                        Text("Event type")
                        
                        Spacer()
                        
                        Picker("", selection: $eventType) {
                            ForEach(doc.contents.eventTypes, id: \.self) { eventType in
                                Text(eventType).tag(eventType)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }
                    .padding(5)
                    
                    Divider()
                    
                    HStack {
                        Text("Event sample")
                        
                        Spacer()
                        
                        TextField("Enter sample number", text: $event)
                            .frame(width: 150)
                    }
                    .padding(5)
                }
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .cancellationAction) {
                Button("Cancel", action: cancel)
            }
            
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Add event", action: addEvent)
                    .disabled(eventIsInvalid)
            }
        }
        .frame(width: 400)
        .task {
            guard let firstEventType = doc.contents.eventTypes.first else {
                return
            }
            
            eventType = firstEventType
        }
    }
    
    func cancel() {
        presentationMode.wrappedValue.dismiss()
    }
    var eventIsInvalid: Bool {
        // Checks if there are samples in the document.
        guard let sampleCount = doc.contents.sampleCount else {
            return true
        }
        
        // Checks if the input is a valid number.
        guard let sampleIndexPlusOne = Int(event) else {
            return true
        }
        
        // Checks if the input is within the sample range.
        guard sampleIndexPlusOne >= 1 && sampleIndexPlusOne <= sampleCount else {
            return true
        }
        
        // Checks whether there is already an event at that sample range.
        guard !doc.contents.events.map({ event in
            event.sampleIndex
        }).contains((sampleIndexPlusOne - 1)) else {
            return true
        }
        
        return false
    }
    func addEvent() {
        guard let sampleIndexPlusOne = Int(event) else {
            return
        }
        
        guard doc.contents.eventTypes.contains(eventType) else {
            return
        }
        
        doc.contents.events.append(Event(sampleIndex: sampleIndexPlusOne - 1, type: eventType))
        presentationMode.wrappedValue.dismiss()
    }
}

struct NewEventView_Previews: PreviewProvider {
    static var previews: some View {
        NewEventView(doc: .constant(TraceDocument()))
    }
}
