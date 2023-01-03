//
//  TraceDocument.swift
//  Trace
//
//  Created by Tahmid Azam on 05/07/2022.
//
//  Copyright (C) 2022 Tahmid Azam
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var trace: UTType {
        UTType(importedAs: "com.Tahmid-Azam.trace")
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
        
        let compressedContents = try JSONDecoder().decode(TraceDocumentContents.self, from: data)
        
        contents = compressedContents
    }
    
    /// Wraps the compressed trace document structure to a file.
    /// - Parameter configuration: The configuration for writing the trace document.
    /// - Returns: A file wrapper of the trace document's data.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(contents)
        
        return .init(regularFileWithContents: data)
    }
}
