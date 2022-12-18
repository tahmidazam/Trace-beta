//
//  EventsView.swift
//  Trace
//
//  Created by Tahmid Azam on 10/12/2022.
//

import SwiftUI

struct EventsView: View {
    @Binding var doc: TraceDocument
    
    enum EventsViewSheet: Identifiable {
        var id: Self { self }
        
        case newEventType, newEvent
    }
    
    @State private var sortOrder = [KeyPathComparator(\Event.sampleIndex)]
    @State var presentedSheet: EventsViewSheet? = nil
    
    var body: some View {
        HSplitView {
            Table(doc.contents.events, sortOrder: $sortOrder) {
                TableColumn("Timestamp/s", value: \.sampleIndex) { value in
                    Text(doc.contents.time(at: value.sampleIndex).format())
                }
                TableColumn("Type", value: \.type)
                TableColumn("Sample number", value: \.sampleIndex) { value in
                    Text("\(value.sampleIndex + 1)")
                }
            }
            .onChange(of: sortOrder) { newValue in
                doc.contents.events.sort(using: newValue)
            }
            
            List {
                Section("Event types") {
                    ForEach(doc.contents.eventTypes, id: \.self) { eventType in
                        LabeledContent(eventType, value: "\(doc.contents.events.filter({ $0.type == eventType }).count)")
                            .contextMenu {
                                Button("Delete", action: {
                                    deleteEventType(eventType: eventType)
                                })
                            }
                    }
                }
            }
        }
        .navigationSubtitle(navigationSubtitleText)
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Button("New event type...", action: newEventTypeButtonAction)
                    
                    Button("New event...", action: newEventButtonAction)
                        .disabled(disableNewEventButton)
                } label: {
                    Label("New", systemImage: "plus")
                }
                
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .newEventType: NewEventTypeView(doc: $doc)
            case .newEvent: NewEventView(doc: $doc)
            }
        }
    }
    
    var navigationSubtitleText: String {
        let eventTypesCount = doc.contents.eventTypes.count
        let eventCount = doc.contents.events.count
        
        return "\(eventTypesCount) event type\(eventTypesCount == 1 ? "" : "s"), \(eventCount) event\(eventCount == 1 ? "" : "s")"
    }
    var disableNewEventButton: Bool {
        return doc.contents.eventTypes.count == 0
    }
    
    func newEventTypeButtonAction() {
        presentedSheet = .newEventType
    }
    func newEventButtonAction() {
        presentedSheet = .newEvent
    }
    func deleteEventType(eventType: String) {
        doc.contents.eventTypes.removeAll { eventType_ in
            eventType_ == eventType
        }
        
        doc.contents.events.removeAll { event in
            event.type == eventType
        }
    }
}
