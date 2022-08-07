//
//  TraceDocument.swift
//  Trace
//
//  Created by Tahmid Azam on 05/07/2022.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var trace: UTType {
        UTType(importedAs: "com.example.trace")
    }
}

/// The trace document structure.
struct TraceDocument: FileDocument {
    /// The content types the trace document can read.
    static var readableContentTypes: [UTType] { [.trace] }
    
    /// The contents of the trace document.
    var contents: TraceDocumentContents
    
    /// Initialises a trace document.
    /// - Parameter trace: the trace stored in the document.
    init(trace: TraceDocumentContents = TraceDocumentContents(streams: [], sampleRate: 200)) {
        self.contents = trace
    }
    
    /// Initialises a trace document by reading a file and decoding and uncompressing its JSON data.
    /// - Parameter configuration: The configuration for reading the trace document.
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let compressedContents = try JSONDecoder().decode(CompressedTraceDocumentContents.self, from: data)
        
        contents = compressedContents.uncompressed()
    }
    
    /// Wraps the compressed trace document structure to a file.
    /// - Parameter configuration: The configuration for writing the trace document.
    /// - Returns: A file wrapper of the trace document's data.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(CompressedTraceDocumentContents(from: contents))
        
        return .init(regularFileWithContents: data)
    }
}
