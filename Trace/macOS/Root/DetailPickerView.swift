//
//  DetailPickerView.swift
//  Trace
//
//  Created by Tahmid Azam on 26/12/2022.
//

import SwiftUI

struct DetailPickerView: View {
    @Binding var doc: TraceDocument
    @Binding var detail: RootView.Detail
    
    var body: some View {
        HStack(spacing: 0.0) {
            ForEach(RootView.Detail.allCases, id: \.self) { detail_ in
                Button {
                    detail = detail_
                } label: {
                    if detail == detail_ {
                        Text(detail_.rawValue.capitalized)
                            .foregroundColor(.white)
                            .padding(2)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 5.0).foregroundColor(.accentColor))
                    } else {
                        Text(detail_.rawValue.capitalized)
                            .padding(2)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 5.0).foregroundColor(.clear))
                    }
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }
}
