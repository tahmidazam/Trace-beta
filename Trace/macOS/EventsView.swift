//
//  EventsView.swift
//  Trace
//
//  Created by Tahmid Azam on 10/12/2022.
//

import SwiftUI

struct EventsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var doc: TraceDocument
    
    enum EventsViewSheet: Identifiable {
        var id: Self { self }
        
        case newEventType, newEvent
    }
    enum EventsViewTab: Identifiable {
        var id: Self { self }
        
        case eventTypes, events
    }
    
    struct EventType: Identifiable {
        var id = UUID()
        var type: String
    }
    
    @State var alert: StreamsViewAlert? = nil

    enum StreamsViewAlert: Identifiable {
        var id: UUID { UUID() }
        
        case fileImportFailure
        case csvFormatInvalid
        
        var alert: Alert {
            switch self {
            case .fileImportFailure: return Alert(title: Text("An error occured."), message: Text("Failed to import file."))
            case .csvFormatInvalid:
                return Alert(title: Text("An error occured."), message: Text("The CSV format is invalid."))
            }
        }
    }
    
    @State var showCSVFileImporter: Bool = false
    
    @State var tab: EventsViewTab = .eventTypes
    @State private var sortOrder = [KeyPathComparator(\Event.sampleIndex)]
    @State var presentedSheet: EventsViewSheet? = nil
    
    #if os(macOS)
    var body: some View {
        NavigationSplitView {
            List(selection: $tab) {
                Label("Event types", systemImage: "square").tag(EventsViewTab.eventTypes)
                Label("Events", systemImage: "square.grid.3x3.square").tag(EventsViewTab.events)
            }
        } detail: {
            switch tab {
            case .eventTypes:
                Table(doc.contents.eventTypes.map({ eventType in
                    EventType(type: eventType)
                })) {
                    TableColumn("Type", value: \.type)
                    
                    TableColumn("Number of events") { value in
                        Text("\(doc.contents.events.filter({ $0.type == value.type }).count)")
                    }
                }
            case .events:
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
            }
        }
        .toolbar {
            ToolbarItemGroup {
                switch tab {
                case .events:
                    Button("New event...", action: newEventButtonAction)
                        .disabled(disableNewEventButton)
                case .eventTypes:
                    Button("New event type...", action: newEventTypeButtonAction)
                }
                
                Button("Import from CSV...") {
                    showCSVFileImporter.toggle()
                }
            }
            
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .newEventType: NewEventTypeView(doc: $doc)
            case .newEvent: NewEventView(doc: $doc)
            }
        }
        .fileImporter(isPresented: $showCSVFileImporter, allowedContentTypes: [.commaSeparatedText, .text], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                processFile(urls: urls)
            case .failure(_):
                alert = .fileImportFailure
            }
        }
        .alert(item: $alert, content: { alert in alert.alert })
    }
    #else
    var body: some View {
        EmptyView()
    }
    #endif
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
    func processFile(urls: [URL]) {
        guard let url = urls.first else { alert = .fileImportFailure; return }
        guard let rawText = try? String(contentsOf: url) else { alert = .fileImportFailure; return }
        guard let sampleCount = doc.contents.sampleCount else { alert = .csvFormatInvalid; return }
        guard let events = TraceDocumentContents.events(from: rawText, sampleRate: doc.contents.sampleRate, sampleCount: sampleCount) else {  alert = .csvFormatInvalid; return }
    
        doc.contents.events = events
        doc.contents.eventTypes = Array(Set(events.map({ event in
            event.type
        })))
    }
}
