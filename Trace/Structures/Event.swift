//
//  Event.swift
//  Trace
//
//  Created by Tahmid Azam on 17/12/2022.
//

import Foundation

struct Event: Identifiable, Codable {
    var id = UUID()
    
    var sampleIndex: Int
    var type: String
    
    static func compress(events: [Event], eventTypes: [String]) -> [String: [Int]] {
        return eventTypes.reduce(into: [String: [Int]]()) { partialResult, eventType in
            let sampleIndices = events.filter { event in
                event.type == eventType
            }.map { event in
                return event.sampleIndex
            }
            
            partialResult[eventType] = sampleIndices
        }
    }
}
