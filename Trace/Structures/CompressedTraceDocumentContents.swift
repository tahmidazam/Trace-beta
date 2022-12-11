//
//  CompressedTraceDocumentContents.swift
//  Trace
//
//  Created by Tahmid Azam on 07/08/2022.
//
//  Copyright (C) 2022 Tahmid Azam
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

import Foundation

/// A compressed format for ``TraceDocumentContents``.
struct CompressedTraceDocumentContents: Codable {
    /// The subject name.
    var subject: String = ""
    /// Information relating to the subject.
    var info: String = ""
    /// The sample rate of the EEG data, measured in Hertz, Hz.
    var sampleRate: Double
    /// A dictionary containing each event type and their events as indexes.
    var events: [String: [Int]] = [:]
    /// Length of an epoch in number of samples
    var epochLength: Int = 100
    /// A dictionary containing each stream, keyed by the stream's electrode and valued by an array of the stream's samples.
    var streams: [String: [Double]]
    
    /// Compresses a ``TraceDocumentContents``.
    /// - Parameter contents: The ``TraceDocumentContents`` instance to compress.
    init(from contents: TraceDocumentContents) {
        subject = contents.subject
        info = contents.info
        sampleRate = contents.sampleRate
        events = contents.events
        epochLength = contents.epochLength
        streams = contents.streams.reduce(into: [String: [Double]]()) { partialResult, stream in
            partialResult[stream.electrode.symbol] = stream.samples
        }
    }
    
    /// Uncompresses a ``TraceDocumentContents``.
    /// - Returns: The uncompressed ``TraceDocumentContents``.
    func uncompressed() -> TraceDocumentContents {
        let uncompressedStreams: [Stream] = streams.compactMap { (key: String, value: [Double]) in
            guard let electrode = Electrode(from: key) else {
                return nil
            }
            
            return Stream(electrode: electrode, samples: value)
        }
        
        return TraceDocumentContents(subject: subject, info: info, streams: uncompressedStreams, sampleRate: sampleRate, events: events, epochLength: epochLength)
    }
}
