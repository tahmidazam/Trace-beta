//
//  DocumentView.swift
//  Trace
//
//  Created by Tahmid Azam on 29/07/2022.
//
//  Copyright (C) 2022 Tahmid Azam
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

import SwiftUI

#if os(iOS)
struct DocumentView: View {
    // MARK: ARGUMENTS
    /// The document to display.
    @Binding var doc: TraceDocument
    
    ///  The search bar text field's text.
    @State var searchText: String = ""
    
    // MARK: MODALS AND ALERTS
    /// The sheet currently being presented, nil if a sheet is not being presented.
    @State var sheet: DocumentViewSheet? = nil
    /// The full screen cover currently being presented, nil if a full screen cover is not being presented.
    @State var fullScreenCover: DocumentViewFullScreenCover? = nil
    /// The alert currently being presented, nil if an alert is not being presented.
    @State var alert: StreamsViewAlert? = nil
    /// True if the file importer modal is being presented, false if not.
    @State var showCSVFileImporter = false
    
    // MARK: COMPUTED PROPERTIES
    
    /// The search suggestions to display.
    var searchSuggestions: [String] {
        Array(Set(doc.contents.streams.map { stream in
            return stream.electrode.prefix.rawValue
        }))
    }
    /// The search results.
    var searchResults: [Stream] {
        return doc.contents.streams.filter { stream in
            stream.electrode.locationDescription.contains(searchText.lowercased()) || stream.electrode.symbol.contains(searchText.lowercased())
        }
    }
    /// Describes the search state. True if the search field is not empty.
    var isSearching: Bool {
        return !searchText.isEmpty
    }
    var documentIsEmpty: Bool {
        doc.contents.streams.isEmpty
    }
    
    // MARK: ENUMERATIONS
    /// The document view's alerts.
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
    /// The document view's sheets.
    enum DocumentViewSheet: Identifiable {
        var id: UUID { UUID() }
        
        case newStreamView, documentPreferencesView
    }
    /// The document view's full screen covers.
    enum DocumentViewFullScreenCover: Identifiable {
        var id: UUID { UUID() }
        
        case scalpMapView, chartView
    }
    
    // MARK: VIEW BODY
    
    var body: some View {
        NavigationStack {
            Group {
                if documentIsEmpty {
                    documentOnboarding
                } else {
                    List {
                        if isSearching {
                            searchResultsListContent
                        } else {
                            streamListContent
                        }
                    }
                    .listStyle(.plain)
                }
            }
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
    
    // MARK: VIEW BODY COMPONENTS - SUBVIEWS
    
    /// Content for the list with search results: a list of streams relevant to the ``searchText``, computed by ``searchResults``.
    var searchResultsListContent: some View {
        ForEach(searchResults) { stream in
            NavigationLink(value: stream) {
                Label {
                    Text(stream.electrode.symbol)
                        .font(.system(.body, design: .monospaced))
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
    /// Formatted count of the streams in the ``doc``.
    var streamCount: String {
        let count = doc.contents.streams.count
        let string = count == 0 ? "" : "\(count) stream\(count == 1 ? "" : "s")"
        
        return string
    }
    /// Content for the document view displayed when ``isSearching`` is false: list of all streams, sectioned by the electrode's prefix and sorted by the electrode's suffix  within those sections.
    var streamListContent: some View {
        ForEach(doc.contents.prefixes, id: \.self) { pre in
            Section {
                let streams = doc.contents.streams.filter { stream in stream.electrode.prefix == pre }.sorted(by: { a, b in
                    a.electrode.suffix < b.electrode.suffix
                })
                
                ForEach(streams) { stream in
                    NavigationLink(value: stream) {
                        Label {
                            Text(stream.electrode.symbol)
                                .font(.system(.body, design: .monospaced))
                        } icon: {
                            switch stream.electrode.generalArea {
                            case .left: Image(systemName: "circle.lefthalf.filled")
                            case .central: Image(systemName: "circle.and.line.horizontal").rotationEffect(.degrees(90))
                            case .right: Image(systemName: "circle.righthalf.filled")
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    let indexedStream = streams[indexSet.first!]
                    
                    doc.contents.streams.removeAll { stream in
                        stream.id == indexedStream.id
                    }
                }
            } header: {
                Text(pre.rawValue)
            }
        }
    }
    /// Content for search suggestions, displayed when searching.
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
    /// The toolbar of the view.
    var toolbarView: some ToolbarContent {
        Group {
            if !documentIsEmpty {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    newStreamButton
                    
                    openDocumentPreferencesButton
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    openScalpMapButton
                    
                    Spacer()
                    
                    documentSummary
                    
                    Spacer()
                    
                    openChartButton
                }
            }
        }
    }
    /// Summary of document details, including the stream count, duration, sample count and sample rate.
    var documentSummary: some View {
        VStack {
            if let duration = doc.contents.duration {
                Text("\(streamCount), \(duration.format()) s")
                    .font(.headline)
            }
            
            if let count = doc.contents.sampleCount {
                Text("\(count) sample\(count == 1 ? "" : "s") @ \(doc.contents.sampleRate.format()) Hz")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    /// Onboarding steps to construct a trace project, displayed when the document is empty.
    var documentOnboarding: some View {
        VStack {
            Text("Get started by importing EEG data into your Trace project.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title3.bold())
                .multilineTextAlignment(.leading)
            
            Text("Import multi-stream data from \(Image(systemName: "rectangle.split.3x3")) CSV, or stream-by-stream from pasted \(Image(systemName: "text.alignleft")) text.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .padding(.top)

            Spacer()
            
            Text("In CSV files, each column represents a stream, with the first cell corresponding to the electrode label, and the rest of the cells form the array of samples. Each column (i.e., each stream) must have the same number of samples, and the electrode label must satisfy the format specified above.\n\nPasted text must be newline-separated values, and electrode information is inputted separately.\n\nInformation about import file requirements, electrode support and general support can be found on the [GitHub page](https://github.com/tahmidazam/Trace).")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack {
                addFromCSVButton
                    .buttonStyle(.borderedProminent)
                
                addFromTextButton
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
            .padding(.top)
        }
        .padding()
    }
    
    // MARK: VIEW BODY COMPONENTS - BUTTONS
    
    /// Button for closing the file and returning to the file picker for the Trace app.
    var closeFileButton: some View {
        Button {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            
            window?.rootViewController?.dismiss(animated: true)
        } label: {
            Label("Close file", systemImage: "chevron.left")
        }
    }
    /// Button for adding a new stream.
    var newStreamButton: some View {
        Menu {
            addFromCSVButton
            addFromTextButton
        } label: {
            Label("New stream", systemImage: "plus")
        }

    }
    /// Button for opening the document preferences sheet.
    var openDocumentPreferencesButton: some View {
        Button {
            sheet = .documentPreferencesView
        } label: {
            Label("Document preferences", systemImage: "ellipsis.circle")
        }
    }
    /// Button for opening the scalp map full screen cover.
    var openScalpMapButton: some View {
        Button {
            fullScreenCover = .scalpMapView
        } label: {
            Label("Open scalp map", systemImage: "circle.dashed")
        }
    }
    /// Button for opening the chart full screen cover.
    var openChartButton: some View {
        Button {
            fullScreenCover = .chartView
        } label: {
            Label("Open chart", systemImage: "chart.xyaxis.line")
        }
    }
    /// Button for importing data from CSV.
    var addFromCSVButton: some View {
        Button {
            showCSVFileImporter.toggle()
        } label: {
            Label("Import from CSV", systemImage: "rectangle.split.3x3")
                .frame(maxWidth: .infinity)
        }
    }
    /// Button for importing data from text.
    var addFromTextButton: some View {
        Button {
            sheet = .newStreamView
        } label: {
            Label("Import from text", systemImage: "text.alignleft")
                .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: FUNCTIONS
    
    /// Imports stream data from CSV.
    /// - Parameter urls: CSV import file.
    func processFile(urls: [URL]) {
        guard let url = urls.first else { alert = .fileImportFailure; return }
        guard let rawText = try? String(contentsOf: url) else { alert = .fileImportFailure; return }
        guard let streams = TraceDocumentContents.streams(from: rawText) else {  alert = .csvFormatInvalid; return }
        
        doc.contents.streams = streams
        
        let allSamples = doc.contents.streams.map { stream in
            return stream.samples
        }.flatMap({ (element: [Double]) -> [Double] in
            return element
        })

        guard let min = allSamples.min() else {  alert = .csvFormatInvalid; return }
        guard let max = allSamples.max() else {  alert = .csvFormatInvalid; return }
        
        doc.contents.potentialRange = min...max
    }
}

struct DocumentView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentView(doc: .constant(TraceDocument(trace: TraceDocumentContents(streams: [Stream(electrode: Electrode(prefix: .frontal, suffix: 1), samples: []), Stream(electrode: Electrode(prefix: .central, suffix: 2), samples: [])], sampleRate: 200))))
    }
}
#endif

