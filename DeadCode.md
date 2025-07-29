                //            let response = try await session.respond(to: prompt, generating: AbstractPsalmResponse.self)
                //
                //            let stream = session.streamResponse(to: prompt, generating: AbstractPsalmResponse.self)
                //
                //            for try await partial in stream {
                //                print(partial)
                //            }
                //
                //
                //            let menuSchema = DynamicGenerationSchema(
                //                name: "Menu",
                //                properties: [
                //                    DynamicGenerationSchema.Property(
                //                        name: "content",
                //                        schema: DynamicGenerationSchema(
                //                            name: "contentSchema",
                //                            anyOf: ["Psalm"]
                //                        )
                //                    )
                //
                //
                //                    // Add additional properties.
                //                ]
                //            )
                //
                //            let schema = try GenerationSchema(root: menuSchema, dependencies: [])
                //
                //
                //            // Pass the schema to the model to guide the output.
                //            let response = try await session.respond(
                //                to: "The prompt you want to make.",
                //                schema: schema
                //            )
                //
                //
                //
                //            let response = try await session.respond(to: prompt)
                //            let generationOptions = GenerationOptions(sampling: GenerationOptions.SamplingMode.greedy, temperature: 0.5, maximumResponseTokens: 16777216)
                //

                
//                await queue.updateResponse(for: abstract.id, response: (try await session.respond(to: prompt/*, options: options*/)).content) //.transcriptEntries.description)
                
                //            for prompt in prompts {
                //                await queue.updateResponse(for: abstract.id, response: (try await session.respond(to: prompt)).content)
                //
                //
                //            }
                
                //            await queue.updateResponse(for: abstract.id, response: (try await session.respond(to: prompts_para1/*, options: options*/)).content) //.transcriptEntries.description)
                //            await queue.updateResponse(for: abstract.id, response: (try await session.respond(to: prompts_para2/*, options: options*/)).content) //.transcriptEntries.description)
    //    func psalmText(from fullText: String, number: Int) -> String? {
    //        guard (1...150).contains(number) else { return nil }
    //        let startMarker = "<<PSALM \(number)>>"
    //        guard let startRange = fullText.range(of: startMarker) else {
    //            return nil
    //        }
    //        let afterStart = startRange.upperBound..<fullText.endIndex
    //        let endMarker: String? = number < 150 ? "<<PSALM \(number + 1)>>" : nil
    //
    //        let endIndex: String.Index
    //        if let next = endMarker,
    //           let nextRange = fullText.range(of: next, options: .literal, range: afterStart) {
    //            endIndex = nextRange.lowerBound
    //        } else {
    //            endIndex = fullText.endIndex
    //        }
    //
    //        let snippet = fullText[startRange.lowerBound..<endIndex]
    //        return snippet.trimmingCharacters(in: .whitespacesAndNewlines)
    //    }


                //                let prompt: Prompt = Prompt("Write an abstract for Psalm \(abstract.psalmNumber) per your instructions. QUOTE OR CITE THE ENTIRE PSALM FIRST!!!")
                
//                let options = GenerationOptions(sampling: .random(top: Int(1.5)), temperature: 0.25, maximumResponseTokens: 8192) //temperature: 0.5)
                
                
                
//                let result = try await session.respond(to: prompt /*, options: options */)
                
                
                
//                await queue.updateResponse(for: abstract.id, response: (try await session.respond(to: prompt/*, options: options*/)).content) //.transcriptEntries.description)
