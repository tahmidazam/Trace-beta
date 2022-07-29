//
//  DocumentView.swift
//  Trace
//
//  Created by Tahmid Azam on 29/07/2022.
//

import SwiftUI

struct DocumentView: View {
    @Binding var doc: TraceDocument
    
    @State var searchText: String = ""
    @State var sheet: DocumentViewSheet? = nil
    @State var alert: StreamsViewAlert? = nil
    @State var showCSVFileImporter = false
    
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
    
    enum DocumentViewSheet: Identifiable {
        var id: UUID { UUID() }
        
        case newStreamView, scalpMapView, chartView, documentPreferencesView
    }
    
    var body: some View {
        NavigationStack {
            List {
                streamListContent
            }
            .listStyle(.plain)
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Stream.self, destination: { stream in StreamDetailView(doc: $doc, stream: stream) })
            .searchable(text: $searchText, prompt: "Find a stream", suggestions: { suggestionsView })
            .toolbar(content: { toolbarView })
            .sheet(item: $sheet, content: { sheet in
                switch sheet {
                case .newStreamView:
                    NewStreamView(document: $doc)
                case .scalpMapView:
                    ScalpMapView(doc: $doc)
                case .chartView:
                    ChartView(doc: $doc)
                case .documentPreferencesView:
                    DocumentPreferencesView(doc: $doc)
                }
            })
            .alert(item: $alert, content: { alert in alert.alert })
            .fileImporter(isPresented: $showCSVFileImporter, allowedContentTypes: [.commaSeparatedText, .text], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    processFile(urls: urls)
                case .failure(_):
                    alert = .fileImportFailure
                }
            }
        }
    }
    
    var navigationTitleText: String {
        let count = doc.contents.streams.count
        
        return count == 0 ? "" : "\(count) stream\(count == 1 ? "" : "s")"
    }
    var searchSuggestions: [String] {
        Array(Set(doc.contents.streams.map { stream in
            return stream.electrode.prefix.rawValue
        }))
    }
    var streamsToDisplay: [Stream] {
        if searchText == "" {
            return doc.contents.streams
        } else {
            return doc.contents.streams.filter { stream in
                stream.electrode.locationDescription.contains(searchText.lowercased()) || stream.electrode.symbol.contains(searchText.lowercased())
            }
        }
    }
    
    var streamListContent: some View {
        ForEach(streamsToDisplay) { stream in
            NavigationLink(value: stream) {
                VStack(alignment: .leading) {
                    Text(stream.electrode.symbol)
                    
                    Text(stream.electrode.locationDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    var suggestionsView: some View {
        Group {
            if searchText == "" {
                Section("By electrode prefix") {
                    ForEach(searchSuggestions, id: \.self) { suggestion in
                        Text(suggestion).searchCompletion(suggestion)
                    }
                }
                
                Section("By lobe") {
                    Text("left").searchCompletion("left")
                    Text("right").searchCompletion("right")
                }
            }
        }
    }
    var toolbarView: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading, content: { closeFileButton })
            
            ToolbarItemGroup(placement: .primaryAction) {
                newStreamButton
                
                openDocumentPreferencesButton
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                openScalpMapButton
                
                Spacer()
                
                timingSummaryView
                
                Spacer()
                
                openChartButton
            }
        }
    }
    var timingSummaryView: some View {
        VStack {
            if let duration = doc.contents.duration {
                Text("\(duration.format()) s")
                    .font(.headline)
            }
            
            if let count = doc.contents.sampleCount {
                Text("\(count) sample\(count == 1 ? "" : "s") @ \(doc.contents.sampleRate.format()) Hz")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var closeFileButton: some View {
        Button {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            
            window?.rootViewController?.dismiss(animated: true)
        } label: {
            Label("Close file", systemImage: "chevron.left")
        }
    }
    var newStreamButton: some View {
        Menu {
            addFromCSVButton
            addFromTextButton
        } label: {
            Label("New stream", systemImage: "plus")
        }

    }
    var openDocumentPreferencesButton: some View {
        Button {
            sheet = .documentPreferencesView
        } label: {
            Label("Document preferences", systemImage: "ellipsis.circle")
        }
    }
    var openScalpMapButton: some View {
        Button {
            sheet = .scalpMapView
        } label: {
            Label("Open scalp map", systemImage: "circle.dashed")
        }
    }
    var openChartButton: some View {
        Button {
            sheet = .chartView
        } label: {
            Label("Open chart", systemImage: "chart.xyaxis.line")
        }
    }
    
    var addFromCSVButton: some View {
        Button {
            showCSVFileImporter.toggle()
        } label: {
            Label("Import from CSV", systemImage: "rectangle.split.3x3")
        }
    }
    var addFromTextButton: some View {
        Button {
            sheet = .newStreamView
        } label: {
            Label("Import from text", systemImage: "text.alignleft")
        }
    }
    
    func processFile(urls: [URL]) {
        guard let url = urls.first else { alert = .fileImportFailure; return }
        guard let rawText = try? String(contentsOf: url) else { alert = .fileImportFailure; return }
        guard let streams = TraceDocumentContents.streams(from: rawText) else {  alert = .csvFormatInvalid; return }
    
        doc.contents.streams = streams
    }
}

struct DocumentView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentView(doc: .constant(TraceDocument(trace: TraceDocumentContents(streams: [Stream(electrode: Electrode(prefix: .frontal, suffix: 1), samples: []), Stream(electrode: Electrode(prefix: .central, suffix: 2), samples: [])], sampleRate: 200))))
    }
}
