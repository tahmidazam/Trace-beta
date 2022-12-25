//
//  TraceApp.swift
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

@main
struct TraceApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TraceDocument()) { file in
            RootView(doc: file.$document)
//            DocumentView(doc: file.$document)
                .task {
                    file.document.contents.streams.sort { lhs, rhs in
                        if lhs.electrode.prefix == rhs.electrode.prefix {
                            return lhs.electrode.suffix < rhs.electrode.suffix
                        }

                        return lhs.electrode.prefix.rawValue < rhs.electrode.prefix.rawValue
                    }
                }
            #if os(iOS)
                .toolbar(.hidden)
            #endif
        }
    }
}
