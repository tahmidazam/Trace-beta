//
//  OnboardingView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var doc: TraceDocument
    @State var showCSVFileImporter: Bool = false
    @State var alert: OnboardingAlert? = nil
    
    enum OnboardingAlert: Identifiable {
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

    var body: some View {
        VStack {
            onboarding
        }
        .frame(maxWidth: 400)
        .padding()
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
    
    var onboarding: some View {
        VStack {
            Text("Get started by importing EEG data into your Trace project")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title3.bold())
                .multilineTextAlignment(.leading)
            
            Text("Import multi-stream data from \(Image(systemName: "rectangle.split.3x3")) CSV")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .padding(.vertical)
            
            Spacer()
            
            Text("In CSV files, each column represents a stream, with the first cell corresponding to the electrode label, and the rest of the cells form the array of samples. Each column (i.e., each stream) must have the same number of samples, and the electrode label must satisfy the format specified above.\n\nInformation about import file requirements, electrode support and general support can be found on the [GitHub page](https://github.com/tahmidazam/Trace).")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            addFromCSVButton
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top)
        }
    }
    
    var addFromCSVButton: some View {
        Button {
            showCSVFileImporter.toggle()
        } label: {
            Label("Import from CSV", systemImage: "rectangle.split.3x3")
                .frame(maxWidth: .infinity)
        }
    }
    
    func processFile(urls: [URL]) {
        guard let url = urls.first else { alert = .fileImportFailure; return }
        guard let fileContents = try? String(contentsOf: url) else { alert = .fileImportFailure; return }
        
        guard let streams = TraceDocumentContents.streams(from: fileContents) else {  alert = .csvFormatInvalid; return }
        
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
