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
    @State var fullScreenCover: DocumentViewFullScreenCover? = nil
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
        
        case newStreamView, documentPreferencesView
    }
    enum DocumentViewFullScreenCover: Identifiable {
        var id: UUID { UUID() }
        
        case scalpMapView, chartView
    }
    
    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    searchResultsListContent
                } else {
                    streamListContent
                }
            }
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Stream.self, destination: { stream in StreamDetailView(doc: $doc, stream: stream) })
            .searchable(text: $searchText, prompt: "Find a stream", suggestions: { suggestionsView })
            .toolbar(content: { toolbarView })
            .sheet(item: $sheet, content: { sheet in
                switch sheet {
                case .newStreamView: NewStreamView(document: $doc)
                case .documentPreferencesView: DocumentPreferencesView(doc: $doc)
                }
            })
            .fullScreenCover(item: $fullScreenCover, content: { fullScreenCover in
                switch fullScreenCover {
                case .chartView: ChartView(doc: $doc)
                case .scalpMapView: ScalpMapView(doc: $doc)
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
    
    var searchResultsListContent: some View {
        ForEach(searchResults) { stream in
            NavigationLink(value: stream) {
                Label {
                    Text(stream.electrode.symbol)
                } icon: {
                    switch stream.electrode.generalArea {
                    case .left: Image(systemName: "circle.lefthalf.filled")
                    case .central: Image(systemName: "circle.and.line.horizontal").rotationEffect(.degrees(90))
                    case .right: Image(systemName: "circle.righthalf.filled")
                    }
                }
            }
        }
    }
    var listHeader: some View {
        let count = doc.contents.streams.count
        let string = count == 0 ? "" : "\(count) stream\(count == 1 ? "" : "s")"
        
        return Text(string)
    }
    var searchSuggestions: [String] {
        Array(Set(doc.contents.streams.map { stream in
            return stream.electrode.prefix.rawValue
        }))
    }
    var searchResults: [Stream] {
        return doc.contents.streams.filter { stream in
            stream.electrode.locationDescription.contains(searchText.lowercased()) || stream.electrode.symbol.contains(searchText.lowercased())
        }
    }
    var isSearching: Bool {
        return !searchText.isEmpty
    }
    
    var streamListContent: some View {
        ForEach(doc.contents.prefixes, id: \.self) { pre in
            Section {
                ForEach(
                    doc.contents.streams.filter { stream in stream.electrode.prefix == pre }.sorted(by: { a, b in
                        a.electrode.suffix > b.electrode.suffix
                    })
                ) { stream in
                    NavigationLink(value: stream) {
                        Label {
                            Text(stream.electrode.symbol)
                        } icon: {
                            switch stream.electrode.generalArea {
                            case .left: Image(systemName: "circle.lefthalf.filled")
                            case .central: Image(systemName: "circle.and.line.horizontal").rotationEffect(.degrees(90))
                            case .right: Image(systemName: "circle.righthalf.filled")
                            }
                        }
                    }
                }
            } header: {
                Text(pre.rawValue)
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
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
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
            fullScreenCover = .scalpMapView
        } label: {
            Label("Open scalp map", systemImage: "circle.dashed")
        }
    }
    var openChartButton: some View {
        Button {
            fullScreenCover = .chartView
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
