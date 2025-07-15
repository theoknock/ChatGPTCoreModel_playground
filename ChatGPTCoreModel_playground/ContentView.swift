//
//  ContentView.swift
//  ChatGPTCoreModel_playground
//
//  Created by Xcode Developer on 7/15/25.
//

import SwiftUI
import SwiftData
import FoundationModels

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var psalmNumber: Int = 34
    @State private var psalmAbstract: String = ""
    
    // Timer properties
    @State private var timer: Timer?
    @State private var timerInterval: TimeInterval = 0.5
    @State private var isIncrementing: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Psalm \(psalmNumber)")
                .font(.title)
            
            HStack(spacing: 40) {
                Button(action: {
                    decrementPsalm()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.largeTitle)
                }
                .simultaneousGesture(
                    LongPressGesture().onEnded { _ in
                        startTimer(incrementing: false)
                    }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0).onEnded { _ in
                        stopTimer()
                    }
                )
                
                Button(action: {
                    incrementPsalm()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                }
                .simultaneousGesture(
                    LongPressGesture().onEnded { _ in
                        startTimer(incrementing: true)
                    }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0).onEnded { _ in
                        stopTimer()
                    }
                )
            }
            
            Button(action: {
                Task {
                    await generatePsalmAbstract()
                }
            }) {
                Label("Generate Abstract", systemImage: "text.book.closed")
            }
            .padding()
            
            ScrollView {
                Text(psalmAbstract)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .border(Color.gray.opacity(0.4))
            
        }
        .padding()
    }
    
    private func incrementPsalm() {
        if psalmNumber < 150 {
            psalmNumber += 1
        }
    }
    
    private func decrementPsalm() {
        if psalmNumber > 1 {
            psalmNumber -= 1
        }
    }
    
    private func startTimer(incrementing: Bool) {
        isIncrementing = incrementing
        timerInterval = 0.5 // start slower
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            if isIncrementing {
                incrementPsalm()
            } else {
                decrementPsalm()
            }
            accelerateScrolling()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func accelerateScrolling() {
        if timerInterval > 0.1 {
            timerInterval -= 0.05
            stopTimer()
            timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
                if isIncrementing {
                    incrementPsalm()
                } else {
                    decrementPsalm()
                }
                accelerateScrolling()
            }
        }
    }
    
    func generatePsalmAbstract() async {
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: """
                AbstractGPT analyzes and summarizes Psalm \(psalmNumber) through a structured, blended approach that combines traditional Christian interpretation with expanded relevance for broader audiences. It produces a rich, multi-layered abstract that includes spiritual insight, theological depth, and real-world application. For each Psalm input, it delivers:

                1. Highlight: Begin with a standout insight or central message that reflects the heart of the Psalm.

                2. Purpose: Clearly articulate the spiritual and emotional purpose of the Psalm, especially how it encourages or guides believers in worship, trust, or repentance.

                3. Themes: Identify and support the Psalm's key themes (e.g., deliverance, divine justice, praise, lament, trust), citing specific verses.

                4. Theological and Christological Summary: In one or two concise paragraphs, explain how the Psalm contributes to an understanding of God, covenant, sin, grace, and salvation, and highlight any direct or indirect references to Christ, the gospel, or messianic fulfillment (with supporting New Testament passages where appropriate).

                5. Framework and Literary Structure: Identify structural patterns (e.g., lament-to-praise, parallelism, covenant appeals) and explain how these support the message of the Psalm.

                6. Memorable Quotes & Dual Interpretation: Extract key verses or phrases from the Psalm and explain each twice:
                   - For believers: as spiritual encouragement, theological depth, or worship guidance
                   - For non-believers: as universal wisdom, poetic insight, or ethical reflection

                7. Real-World Application: Offer practical, contemporary ways to apply the Psalm’s message, including illustrative case studies from personal experience, church history, or broader culture.

                8. Comparative Insight: Reference other psalms that are thematically, structurally, or emotionally similar, with a short explanation of how they relate or differ.

                9. Audience Contextualization: Explain how the Psalm’s message could be presented to believers, non-believers, or spiritually curious audiences, with attention to tone, relevance, and interpretive angle.

                All responses should remain concise but thorough, typically organized in six paragraphs or an equivalent structured format. The tone should be respectful, theologically grounded, and accessible to a wide readership.

                DO NOT ADD HEADERS.
                """
            )
            
            $psalmAbstract.wrappedValue = response.content // Or response.content
        } catch {
            psalmAbstract = "Failed to generate abstract: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}


////
////  ContentView.swift
////  ChatGPTCoreModel_playground
////
////  Created by Xcode Developer on 7/15/25.
////
//
//import SwiftUI
//import SwiftData
//import FoundationModels
//
//struct ContentView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Query private var items: [Item]
//    
//    @State private var psalmNumber: Int = 34 // ✅ Default Psalm number
//    @State private var psalmAbstract: String = "" // ✅ Holds the generated response
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            // ✅ Number Stepper
//            Stepper("Psalm \(psalmNumber)", value: $psalmNumber, in: 1...150)
//                .padding()
//            
//            // ✅ Generate Button
//            Button(action: {
//                Task {
//                    await generatePsalmAbstract()
//                }
//            }) {
//                Label("Generate Abstract", systemImage: "text.book.closed")
//            }
//            .padding()
//            
//            // ✅ Scrollable Text View for Response
//            ScrollView {
//                Text(psalmAbstract)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding()
//            }
//            .border(Color.gray.opacity(0.4))
//        }
//        .padding()
//    }
//    
//    func generatePsalmAbstract() async {
//        do {
//            let session = LanguageModelSession()
//            let response = try await session.respond(to: """
//                AbstractGPT analyzes and summarizes Psalm \(psalmNumber) through a structured, blended approach that combines traditional Christian interpretation with expanded relevance for broader audiences. It produces a rich, multi-layered abstract that includes spiritual insight, theological depth, and real-world application. For each Psalm input, it delivers:
//
//                1. Highlight: Begin with a standout insight or central message that reflects the heart of the Psalm.
//
//                2. Purpose: Clearly articulate the spiritual and emotional purpose of the Psalm, especially how it encourages or guides believers in worship, trust, or repentance.
//
//                3. Themes: Identify and support the Psalm's key themes (e.g., deliverance, divine justice, praise, lament, trust), citing specific verses.
//
//                4. Theological and Christological Summary: In one or two concise paragraphs, explain how the Psalm contributes to an understanding of God, covenant, sin, grace, and salvation, and highlight any direct or indirect references to Christ, the gospel, or messianic fulfillment (with supporting New Testament passages where appropriate).
//
//                5. Framework and Literary Structure: Identify structural patterns (e.g., lament-to-praise, parallelism, covenant appeals) and explain how these support the message of the Psalm.
//
//                6. Memorable Quotes & Dual Interpretation: Extract key verses or phrases from the Psalm and explain each twice:
//                   - For believers: as spiritual encouragement, theological depth, or worship guidance
//                   - For non-believers: as universal wisdom, poetic insight, or ethical reflection
//
//                7. Real-World Application: Offer practical, contemporary ways to apply the Psalm’s message, including illustrative case studies from personal experience, church history, or broader culture.
//
//                8. Comparative Insight: Reference other psalms that are thematically, structurally, or emotionally similar, with a short explanation of how they relate or differ.
//
//                9. Audience Contextualization: Explain how the Psalm’s message could be presented to believers, non-believers, or spiritually curious audiences, with attention to tone, relevance, and interpretive angle.
//
//                All responses should remain concise but thorough, typically organized in six paragraphs or an equivalent structured format. The tone should be respectful, theologically grounded, and accessible to a wide readership.
//
//                DO NOT ADD HEADERS.
//                """
//            )
//            
//            $psalmAbstract.wrappedValue = response.content // ✅ Or use .content if that’s the actual property
//        } catch {
//            psalmAbstract = "Failed to generate abstract: \(error.localizedDescription)"
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
//
//
//
////import SwiftUI
////import SwiftData
////import FoundationModels
////
////struct ContentView: View {
////    @Environment(\.modelContext) private var modelContext
////    @Query private var items: [Item]
////    
////    @State private var psalm34Abstract: String = "" // ✅ State to hold the response
////    
////    var body: some View {
////        
////        Button(action: {
////            Task {
////                await getPsalm34Abstract()
////            }
////        }) {
////            Label("Get Psalm 34 Abstract", systemImage: "text.book.closed")
////        }
////        
////        Text($psalm34Abstract.wrappedValue)
////    }
////
////
////func getPsalm34Abstract() async {
////    do {
////        let session = LanguageModelSession()
////        let response = try await session.respond(to: """
////            AbstractGPT analyzes and summarizes any given Psalm through a structured, blended approach that combines traditional Christian interpretation with expanded relevance for broader audiences. It produces a rich, multi-layered abstract that includes spiritual insight, theological depth, and real-world application. For each Psalm input, it delivers:
////
////            1. **Highlight:** Begin with a standout insight or central message that reflects the heart of the Psalm.
////
////            2. **Purpose:** Clearly articulate the spiritual and emotional purpose of the Psalm, especially how it encourages or guides believers in worship, trust, or repentance.
////
////            3. **Themes:** Identify and support the Psalm's key themes (e.g., deliverance, divine justice, praise, lament, trust), citing specific verses.
////
////            4. **Theological and Christological Summary:** In one or two concise paragraphs, explain how the Psalm contributes to an understanding of God, covenant, sin, grace, and salvation, and highlight any direct or indirect references to Christ, the gospel, or messianic fulfillment (with supporting New Testament passages where appropriate).
////
////            5. **Framework and Literary Structure:** Identify structural patterns (e.g., lament-to-praise, parallelism, covenant appeals) and explain how these support the message of the Psalm.
////
////            6. **Memorable Quotes & Dual Interpretation:** Extract key verses or phrases from the Psalm and explain each twice:
////               - For **believers**: as spiritual encouragement, theological depth, or worship guidance
////               - For **non-believers**: as universal wisdom, poetic insight, or ethical reflection
////
////            7. **Real-World Application:** Offer practical, contemporary ways to apply the Psalm’s message, including illustrative case studies from personal experience, church history, or broader culture.
////
////            8. **Comparative Insight:** Reference other psalms that are thematically, structurally, or emotionally similar, with a short explanation of how they relate or differ.
////
////            9. **Audience Contextualization:** Explain how the Psalm’s message could be presented to believers, non-believers, or spiritually curious audiences, with attention to tone, relevance, and interpretive angle.
////
////            All responses should remain concise but thorough, typically organized in six paragraphs or an equivalent structured format. The tone should be respectful, theologically grounded, and accessible to a wide readership.
////
////            DO NOT ADD HEADERS.
////            """)
////        $psalm34Abstract.wrappedValue = response.content // If '.value' is not correct, use the actual property name that contains the String in LanguageModelSession.Response<String>
////    } catch {
////        psalm34Abstract = "Failed to generate abstract: \(error.localizedDescription)"
////    }
////}
////
////private func addItem() {
////    withAnimation {
////        let newItem = Item(timestamp: Date())
////        modelContext.insert(newItem)
////    }
////}
////
////private func deleteItems(offsets: IndexSet) {
////    withAnimation {
////        for index in offsets {
////            modelContext.delete(items[index])
////        }
////    }
////}
////}
////
////#Preview {
////    ContentView()
////        .modelContainer(for: Item.self, inMemory: true)
////}
