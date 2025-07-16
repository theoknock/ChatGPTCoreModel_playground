//
//  AbstractPsalmResponse.swift
//  ChatGPTCoreModel_playground
//
//  Created by Xcode Developer on 7/16/25.
//

import Foundation
import FoundationModels

@Generable struct AbstractPsalmResponse {
    @Guide(description: "A blend of theological, literary, and practical analysis of the given psalm.", .count(1))
    var abstractPsalmResponse: [String]
}
