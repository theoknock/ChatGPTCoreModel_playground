//
//  Playground_File.swift
//  ChatGPTCoreModel_playground
//
//  Created by Xcode Developer on 7/15/25.
//

import Foundation
import Playgrounds
import FoundationModels

#Playground {
    let session  = LanguageModelSession()
    let response = try await session.respond(to: """
Write an abstract of Psalm 34 that is concise (no  more than a few hundred words), able to stand alone, and allows readers to quickly determine its relevance and scope. Use keywords common to biblical literary review that reflect the main topics or concepts

Structure the abstract accordingly:

Briefly state the purpose or objective of the psalm and its spiritual significance  
Identify the key theme and summarize its main points
Prove its modern relevance by making corollaries between its meaning and purpose and the Christian faith
Keywords: Often, abstracts include a list of covered in the literature. This aids in the indexing and searching of the work.
"""
    )
    print(response)
}
