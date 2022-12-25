//
//  NewEventTypeView.swift
//  Trace
//
//  Created by Tahmid Azam on 18/12/2022.
//

import SwiftUI

struct NewEventTypeView: View {
    @Binding var doc: TraceDocument
    
    @State var eventType: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("New event type")
                .font(.headline)
            
            Text("Tag each event sample/timestamp with a descriptor of the event's stimulus to enable selective epoching.")
                .fixedSize(horizontal: false, vertical: true)
            
            GroupBox {
                HStack {
                    Text("Event type")
                    
                    Spacer()
                    
                    TextField("Enter event type", text: $eventType)
                        .frame(width: 150)
                }
                .padding(5)
            }
            .padding(.top)
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .cancellationAction) {
                Button("Cancel", action: cancel)
            }
            
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Add event type", action: addEventType)
                    .disabled(eventTypeIsInvalid)
            }
        }
        .frame(width: 400)
    }
    
    func cancel() {
        presentationMode.wrappedValue.dismiss()
    }
    var eventTypeIsInvalid: Bool {
        eventType.count == 0 || eventType.count > 100
    }
    func addEventType() {
        doc.contents.eventTypes.append(eventType)
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct NewEventTypeView_Previews: PreviewProvider {
    static var previews: some View {
        NewEventTypeView(doc: .constant(TraceDocument()))
    }
}
