//
//  StreamView.swift
//  ChatGPTCoreModel_playground
//
//  Created by Xcode Developer on 7/16/25.
//

import Foundation
import SwiftUI
import FoundationModels

struct StreamView: View {
    let session: LanguageModelSession
    let dayCount: Int
    let landmarkName: String
  
    @State
    private var itinerary: AbstractPsalmResponse.PartiallyGenerated?
  
    var body: some View {
        //...
        Button("Start") {
            Task {
                do {
                    let prompt = """
                        
                        """
                  
                    let stream = session.streamResponse(
                        to: prompt,
                        generating: AbstractPsalmResponse.self
                    )
                  
                    for try await partial in stream {
                        self.itinerary = partial
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}
