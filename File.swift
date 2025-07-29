//
//  File.swift
//  ChatGPTCoreModel_playground
//
//  Created by Xcode Developer on 7/29/25.
//


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