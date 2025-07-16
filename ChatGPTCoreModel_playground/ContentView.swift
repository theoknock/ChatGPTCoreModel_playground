//
//  ContentView.swift
//  ChatGPTCoreModel_playground
//
//  Created by Xcode Developer on 7/15/25.
//

import SwiftUI
import FoundationModels

// MARK: - Model for a single queued Psalm abstract
struct PsalmAbstract: Identifiable {
    let id = UUID()
    let psalmNumber: Int
    var response: String = "Pending..."
    var isCompleted: Bool = false
}

// MARK: - Actor for safe queueing
actor PsalmQueue {
    private(set) var items: [PsalmAbstract] = []
    
    func addPsalm(_ psalmNumber: Int) -> PsalmAbstract {
        let abstract = PsalmAbstract(psalmNumber: psalmNumber)
        items.append(abstract)
        return abstract
    }
    
    func updateResponse(for id: UUID, response: String) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].response = response
            items[index].isCompleted = true
        }
    }
    
    var currentItems: [PsalmAbstract] {
        items
    }
}

// MARK: - Main View
struct ContentView: View {
    @State private var psalmNumber: Int = .zero
    @State private var psalmNumberInput: String = String()
    var quotedPsalmNumberInput: Binding<String> {
        Binding<String>(
            get: {
                "\(psalmNumberInput)"
            },
            set: { newValue in
                if newValue.hasPrefix("\"") && newValue.hasSuffix("\"") {
                    psalmNumberInput = String(newValue.dropFirst().dropLast())
                } else {
                    psalmNumberInput = newValue
                }
            }
        )
    }
    @State private var abstracts: [PsalmAbstract] = []
    
    private let queue = PsalmQueue()
    
    // Timer properties for stepper acceleration
    @State private var timer: Timer?
    @State private var timerInterval: TimeInterval = 0.5
    @State private var isIncrementing: Bool = true
    
    var body: some View {
        ZStack {
            // Linear gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primary.opacity(0.25),
                    Color.accentColor.opacity(0.25)
                ]),
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
            .ignoresSafeArea()
            
            VStack(content: {
//                Text("Psalm")
//                    .font(.title2)
                
                ZStack(alignment: (.trailing), content: {
                    
                    HStack {
                        TextField(("Enter a psalm (1-150)..."), text: $psalmNumberInput, axis: .horizontal)
                            .padding(.leading)
                        Spacer()
                    }
                    
                    
                    HStack {
                        HStack {
                            Button(action: {
                                decrementPsalm()
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(Color(UIColor.white))
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.largeTitle)
                                    .imageScale(.small)
                                    .labelStyle(.iconOnly)
                                    .clipShape(Circle())
                                    .padding(8)
                                    .glassEffect()
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
                            .padding(.leading, 2)
                            .buttonStyle(PlainButtonStyle())
                            .shadow(color: Color.white.opacity(0.5), radius: 2, x: 2, y: 2)
                            
                            Spacer()
                            
                            // Number input field
                            TextField("Psalm \(psalmNumber)", text: quotedPsalmNumberInput) //"Psalm", text: $psalmNumberInput)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(DefaultTextFieldStyle())
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
                            
                                .onChange(of: psalmNumberInput) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if let value = Int(filtered) {
                                        psalmNumber = min(max(value, 1), 150)
                                    }
                                    psalmNumberInput = "\(psalmNumber)"
                                }
                                .font(.largeTitle)
                                .foregroundColor(Color(UIColor.white))
                                .background(Color(UIColor.clear))
                                .padding(4)
                            
                            Spacer()
                            
                            Button(action: {
                                incrementPsalm()
                            }) {
                                Image(systemName: "plus.circle")
                                    .padding(8)
                                    .foregroundColor(Color(UIColor.white))
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.largeTitle)
                                    .imageScale(.small)
                                    .labelStyle(.iconOnly)
                                    .clipShape(Circle())
                                    .glassEffect()
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
                            .padding(.trailing, 2)
                            .buttonStyle(PlainButtonStyle())
                            .shadow(color: Color.white.opacity(0.5), radius: 2, x: 2, y: 2)
                        }
                    }
                    .background(Color.init(uiColor: UIColor(white: 1.0, alpha: 0.2)))
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25), style: .continuous))
                    .padding(.trailing, 75)
                    
                    Button {
                        dismissKeyboard()
                        addPsalmAndRun()
                    } label: {
                        Image(systemName: "pencil")
                            .padding(8)
                            .foregroundColor(Color(UIColor.white))
                            .symbolRenderingMode(.monochrome)
                            .font(.largeTitle)
                            .imageScale(.medium)
                            .labelStyle(.iconOnly)
                            .clipShape(Circle())
                    }
//                    .padding(.leading, 100)
                    .glassEffect(in: .rect(cornerRadius: 25.0))
                    .shadow(color: Color.white.opacity(0.5), radius: 2, x: 2, y: 2)
                })
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(abstracts) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Psalm \(item.psalmNumber)")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .padding(.vertical)
                                    .frame(idealWidth: UIScreen.main.bounds.size.width, maxWidth: UIScreen.main.bounds.size.width)
                                    .glassEffect(in: .rect(cornerRadius: 25.0))
                                
                                if item.isCompleted {
                                    Text(item.response)
                                        .dynamicTypeSize(DynamicTypeSize.xSmall)
                                        .font(.body)
                                        .frame(maxWidth: UIScreen.main.bounds.size.width)
                                } else {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(28)
                            .glassEffect(in: .rect(cornerRadius: 25.0))
                            .padding(.vertical)
                        }
                    }
//                    .padding(.bottom, 50)
                    
                    
                    Spacer()
                }
//                .frame(width: .infinity, height: .infinity)
//                .border(Color.white.opacity(1.0), width: 0.2)
//                .backgroundStyle(Color.white.opacity(1.0))
                .ignoresSafeArea()
            })
            .padding()
            .onAppear {
                psalmNumberInput = "\(psalmNumber)"
                Task {
                    await refreshQueue()
                }
            }
            
            
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, content: {
                    Spacer()
                    
                    Text("James Alan Bush")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Commit ID 0863a4e")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                })
            }
            
//            .frame(width: .infinity, height: .infinity)
//            .border(Color.white.opacity(1.0), width: 0.2)
//            .backgroundStyle(Color.white.opacity(1.0))
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Stepper Logic
    private func incrementPsalm() {
        if psalmNumber < 150 {
            psalmNumber += 1
            psalmNumberInput = "\(psalmNumber)"
        }
    }
    
    private func decrementPsalm() {
        if psalmNumber > 1 {
            psalmNumber -= 1
            psalmNumberInput = "\(psalmNumber)"
        }
    }
    
    private func startTimer(incrementing: Bool) {
        isIncrementing = incrementing
        timerInterval = 0.5
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
    
    // MARK: - Add & Execute
    private func addPsalmAndRun() {
        Task {
            let abstract = await queue.addPsalm(psalmNumber)
            await refreshQueue()
            
            Task.detached {
                await runPsalmAbstract(abstract)
            }
        }
    }
    
    private func runPsalmAbstract(_ abstract: PsalmAbstract) async {
        do {
            let instructions: Instructions = Instructions("""
            Your instructions:
            
            When prompted with a specific psalm (e.g., “Psalm 23” or “23”), you will write a six-paragraph abstract of psalm \(abstract.psalmNumber). Following is a description of each paragraph (i.e., its topic); do not number the paragraphs or precede each paragraph with a topic summation:

            1. The abstract should begin with a key highlight that best represents the central message or emphasis of the Psalm, reflecting its specific content and significance.
            2. Clearly describe the purpose of the Psalm, explaining its spiritual intent and how it serves or helps the believer. Avoid mentioning the writer unless referring to the Psalm’s direct impact on worship or spiritual life.
            3. Identify and summarize the key themes found in the psalm, supported by references from the text itself.
            4. Provide a theological summary that explains how the psalm’s message contributes to an understanding of God, faith, and spiritual matters.
            5. Write a Christological summary that identifies any direct or indirect connections to Christ, the gospel, or messianic prophecies.
            6. Draw direct parallels to Christian teachings, using New Testament scriptures to illustrate how the message of the psalm is fulfilled or mirrored in Christ and His teachings, and give advice on how Christians today can apply the psalm’s lessons in their own lives.
            """)

            let session: LanguageModelSession = LanguageModelSession(instructions: instructions)

            let prompt: Prompt = Prompt("Write an abstract for Psalm \(abstract.psalmNumber) per your instructions.")
//            let response = try await session.respond(to: prompt, generating: AbstractPsalmResponse.self)
            
//            let stream = session.streamResponse(to: prompt, generating: AbstractPsalmResponse.self)
//            
//            for try await partial in stream {
//                print(partial)
//            }
//            let response = try await session.respond(to: prompt)
            await queue.updateResponse(for: abstract.id, response: (try await session.respond(to: prompt)).content) //.transcriptEntries.description)
        } catch {
            await queue.updateResponse(for: abstract.id, response: "Error: \(error.localizedDescription)")
        }
        await refreshQueue()
    }
    
    
    @MainActor
    private func refreshQueue() async {
        abstracts = await queue.currentItems
    }
}



#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}


////
////  ContentView.swift
////  ChatGPTCoreModel_playground
////
////  Created by Xcode Developer on 7/15/25.
////
//
//import SwiftUI
//import FoundationModels
//
//struct ContentView: View {
//
//    // Example queued prompts
//    @State private var prompts: [String] = [
//        """
//        Write an abstract of Psalm 1 that is concise, stand-alone, and includes modern relevance.
//        """,
//        """
//        Write an abstract of Psalm 23 that is concise, stand-alone, and includes modern relevance.
//        """,
//        """
//        Write an abstract of Psalm 34 that is concise, stand-alone, and includes modern relevance.
//        """
//    ]
//
//    // Results of each response
//    @State private var results: [PromptResult] = []
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("Queued Prompts")
//                .font(.headline)
//
//            List {
//                ForEach(prompts, id: \.self) { prompt in
//                    Text(prompt.prefix(50) + "...")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//            }
//            .frame(height: 200)
//
//            Button("Run All Prompts") {
//                Task {
//                    await runAllPrompts()
//                }
//            }
//            .padding()
//
//            Text("Results")
//                .font(.headline)
//
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    ForEach(results) { result in
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Prompt:")
//                                .font(.subheadline)
//                                .bold()
//                            Text(result.prompt)
//                                .font(.footnote)
//                                .foregroundColor(.secondary)
//
//                            Text("Response:")
//                                .font(.subheadline)
//                                .bold()
//                            Text(result.response)
//                                .font(.body)
//                        }
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                    }
//                }
//                .padding()
//            }
//        }
//        .padding()
//    }
//
//    func runAllPrompts() async {
//        results = [] // Clear previous results
//
//        await withTaskGroup(of: PromptResult?.self) { group in
//            for prompt in prompts {
//                group.addTask {
//                    do {
//                        let session = LanguageModelSession()
//                        let response = try await session.respond(to: prompt)
//                        let text = response.content // or .content depending on your API
//                        return PromptResult(prompt: prompt, response: text)
//                    } catch {
//                        return PromptResult(prompt: prompt, response: "Error: \(error.localizedDescription)")
//                    }
//                }
//            }
//
//            for await result in group {
//                if let result = result {
//                    await MainActor.run {
//                        results.append(result)
//                    }
//                }
//            }
//        }
//    }
//}
//
//struct PromptResult: Identifiable {
//    let id = UUID()
//    let prompt: String
//    let response: String
//}
//
//#Preview {
//    ContentView()
//}
//
//
//////
//////  ContentView.swift
//////  ChatGPTCoreModel_playground
//////
//////  Created by Xcode Developer on 7/15/25.
//////
////
////import SwiftUI
////import SwiftData
////import FoundationModels
////
////struct ContentView: View {
////    @Environment(\.modelContext) private var modelContext
////    @Query private var items: [Item]
////
////    @State private var psalmNumber: Int = 34
////    @State private var psalmAbstract: String = ""
////
////    // Timer properties
////    @State private var timer: Timer?
////    @State private var timerInterval: TimeInterval = 0.5
////    @State private var isIncrementing: Bool = true
////
////    var body: some View {
////        VStack(spacing: 20) {
////
////            Text("Psalm \(psalmNumber)")
////                .font(.title)
////
////            HStack(spacing: 40) {
////                Button(action: {
////                    decrementPsalm()
////                }) {
////                    Image(systemName: "minus.circle.fill")
////                        .font(.largeTitle)
////                }
////                .simultaneousGesture(
////                    LongPressGesture().onEnded { _ in
////                        startTimer(incrementing: false)
////                    }
////                )
////                .simultaneousGesture(
////                    DragGesture(minimumDistance: 0).onEnded { _ in
////                        stopTimer()
////                    }
////                )
////
////                Button(action: {
////                    incrementPsalm()
////                }) {
////                    Image(systemName: "plus.circle.fill")
////                        .font(.largeTitle)
////                }
////                .simultaneousGesture(
////                    LongPressGesture().onEnded { _ in
////                        startTimer(incrementing: true)
////                    }
////                )
////                .simultaneousGesture(
////                    DragGesture(minimumDistance: 0).onEnded { _ in
////                        stopTimer()
////                    }
////                )
////            }
////
////            Button(action: {
////                Task {
////                    await generatePsalmAbstract()
////                }
////            }) {
////                Label("Generate Abstract", systemImage: "text.book.closed")
////            }
////            .padding()
////
////            ScrollView {
////                Text(psalmAbstract)
////                    .frame(maxWidth: .infinity, alignment: .leading)
////                    .padding()
////            }
////            .border(Color.gray.opacity(0.4))
////
////        }
////        .padding()
////    }
////
////    private func incrementPsalm() {
////        if psalmNumber < 150 {
////            psalmNumber += 1
////        }
////    }
////
////    private func decrementPsalm() {
////        if psalmNumber > 1 {
////            psalmNumber -= 1
////        }
////    }
////
////    private func startTimer(incrementing: Bool) {
////        isIncrementing = incrementing
////        timerInterval = 0.5 // start slower
////        stopTimer()
////
////        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
////            if isIncrementing {
////                incrementPsalm()
////            } else {
////                decrementPsalm()
////            }
////            accelerateScrolling()
////        }
////    }
////
////    private func stopTimer() {
////        timer?.invalidate()
////        timer = nil
////    }
////
////    private func accelerateScrolling() {
////        if timerInterval > 0.1 {
////            timerInterval -= 0.05
////            stopTimer()
////            timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
////                if isIncrementing {
////                    incrementPsalm()
////                } else {
////                    decrementPsalm()
////                }
////                accelerateScrolling()
////            }
////        }
////    }
////
////    func generatePsalmAbstract() async {
////        do {
////            let session = LanguageModelSession()
////            let response = try await session.respond(to: """
////                AbstractGPT analyzes and summarizes Psalm \(psalmNumber) through a structured, blended approach that combines traditional Christian interpretation with expanded relevance for broader audiences. It produces a rich, multi-layered abstract that includes spiritual insight, theological depth, and real-world application. For each Psalm input, it delivers:
////
////                1. Highlight: Begin with a standout insight or central message that reflects the heart of the Psalm.
////
////                2. Purpose: Clearly articulate the spiritual and emotional purpose of the Psalm, especially how it encourages or guides believers in worship, trust, or repentance.
////
////                3. Themes: Identify and support the Psalm's key themes (e.g., deliverance, divine justice, praise, lament, trust), citing specific verses.
////
////                4. Theological and Christological Summary: In one or two concise paragraphs, explain how the Psalm contributes to an understanding of God, covenant, sin, grace, and salvation, and highlight any direct or indirect references to Christ, the gospel, or messianic fulfillment (with supporting New Testament passages where appropriate).
////
////                5. Framework and Literary Structure: Identify structural patterns (e.g., lament-to-praise, parallelism, covenant appeals) and explain how these support the message of the Psalm.
////
////                6. Memorable Quotes & Dual Interpretation: Extract key verses or phrases from the Psalm and explain each twice:
////                   - For believers: as spiritual encouragement, theological depth, or worship guidance
////                   - For non-believers: as universal wisdom, poetic insight, or ethical reflection
////
////                7. Real-World Application: Offer practical, contemporary ways to apply the Psalm’s message, including illustrative case studies from personal experience, church history, or broader culture.
////
////                8. Comparative Insight: Reference other psalms that are thematically, structurally, or emotionally similar, with a short explanation of how they relate or differ.
////
////                9. Audience Contextualization: Explain how the Psalm’s message could be presented to believers, non-believers, or spiritually curious audiences, with attention to tone, relevance, and interpretive angle.
////
////                All responses should remain concise but thorough, typically organized in six paragraphs or an equivalent structured format. The tone should be respectful, theologically grounded, and accessible to a wide readership.
////
////                DO NOT ADD HEADERS.
////                """
////            )
////
////            $psalmAbstract.wrappedValue = response.content
////        } catch {
////            psalmAbstract = "Failed to generate abstract: \(error.localizedDescription)"
////        }
////    }
////}
////
////#Preview {
////    ContentView()
////        .modelContainer(for: Item.self, inMemory: true)
////}
////
////
////////
////////  ContentView.swift
////////  ChatGPTCoreModel_playground
////////
////////  Created by Xcode Developer on 7/15/25.
////////
//////
//////import SwiftUI
//////import SwiftData
//////import FoundationModels
//////
//////struct ContentView: View {
//////    @Environment(\.modelContext) private var modelContext
//////    @Query private var items: [Item]
//////
//////    @State private var psalmNumber: Int = 34 // ✅ Default Psalm number
//////    @State private var psalmAbstract: String = "" // ✅ Holds the generated response
//////
//////    var body: some View {
//////        VStack(spacing: 20) {
//////            // ✅ Number Stepper
//////            Stepper("Psalm \(psalmNumber)", value: $psalmNumber, in: 1...150)
//////                .padding()
//////
//////            // ✅ Generate Button
//////            Button(action: {
//////                Task {
//////                    await generatePsalmAbstract()
//////                }
//////            }) {
//////                Label("Generate Abstract", systemImage: "text.book.closed")
//////            }
//////            .padding()
//////
//////            // ✅ Scrollable Text View for Response
//////            ScrollView {
//////                Text(psalmAbstract)
//////                    .frame(maxWidth: .infinity, alignment: .leading)
//////                    .padding()
//////            }
//////            .border(Color.gray.opacity(0.4))
//////        }
//////        .padding()
//////    }
//////
//////    func generatePsalmAbstract() async {
//////        do {
//////            let session = LanguageModelSession()
//////            let response = try await session.respond(to: """
//////                AbstractGPT analyzes and summarizes Psalm \(psalmNumber) through a structured, blended approach that combines traditional Christian interpretation with expanded relevance for broader audiences. It produces a rich, multi-layered abstract that includes spiritual insight, theological depth, and real-world application. For each Psalm input, it delivers:
//////
//////                1. Highlight: Begin with a standout insight or central message that reflects the heart of the Psalm.
//////
//////                2. Purpose: Clearly articulate the spiritual and emotional purpose of the Psalm, especially how it encourages or guides believers in worship, trust, or repentance.
//////
//////                3. Themes: Identify and support the Psalm's key themes (e.g., deliverance, divine justice, praise, lament, trust), citing specific verses.
//////
//////                4. Theological and Christological Summary: In one or two concise paragraphs, explain how the Psalm contributes to an understanding of God, covenant, sin, grace, and salvation, and highlight any direct or indirect references to Christ, the gospel, or messianic fulfillment (with supporting New Testament passages where appropriate).
//////
//////                5. Framework and Literary Structure: Identify structural patterns (e.g., lament-to-praise, parallelism, covenant appeals) and explain how these support the message of the Psalm.
//////
//////                6. Memorable Quotes & Dual Interpretation: Extract key verses or phrases from the Psalm and explain each twice:
//////                   - For believers: as spiritual encouragement, theological depth, or worship guidance
//////                   - For non-believers: as universal wisdom, poetic insight, or ethical reflection
//////
//////                7. Real-World Application: Offer practical, contemporary ways to apply the Psalm’s message, including illustrative case studies from personal experience, church history, or broader culture.
//////
//////                8. Comparative Insight: Reference other psalms that are thematically, structurally, or emotionally similar, with a short explanation of how they relate or differ.
//////
//////                9. Audience Contextualization: Explain how the Psalm’s message could be presented to believers, non-believers, or spiritually curious audiences, with attention to tone, relevance, and interpretive angle.
//////
//////                All responses should remain concise but thorough, typically organized in six paragraphs or an equivalent structured format. The tone should be respectful, theologically grounded, and accessible to a wide readership.
//////
//////                DO NOT ADD HEADERS.
//////                """
//////            )
//////
//////            $psalmAbstract.wrappedValue = response.content // ✅ Or use .content if that’s the actual property
//////        } catch {
//////            psalmAbstract = "Failed to generate abstract: \(error.localizedDescription)"
//////        }
//////    }
//////}
//////
//////#Preview {
//////    ContentView()
//////        .modelContainer(for: Item.self, inMemory: true)
//////}
//////
//////
//////
////////import SwiftUI
////////import SwiftData
////////import FoundationModels
////////
////////struct ContentView: View {
////////    @Environment(\.modelContext) private var modelContext
////////    @Query private var items: [Item]
////////
////////    @State private var psalm34Abstract: String = "" // ✅ State to hold the response
////////
////////    var body: some View {
////////
////////        Button(action: {
////////            Task {
////////                await getPsalm34Abstract()
////////            }
////////        }) {
////////            Label("Get Psalm 34 Abstract", systemImage: "text.book.closed")
////////        }
////////
////////        Text($psalm34Abstract.wrappedValue)
////////    }
////////
////////
////////func getPsalm34Abstract() async {
////////    do {
////////        let session = LanguageModelSession()
////////        let response = try await session.respond(to: """
////////            AbstractGPT analyzes and summarizes any given Psalm through a structured, blended approach that combines traditional Christian interpretation with expanded relevance for broader audiences. It produces a rich, multi-layered abstract that includes spiritual insight, theological depth, and real-world application. For each Psalm input, it delivers:
////////
////////            1. **Highlight:** Begin with a standout insight or central message that reflects the heart of the Psalm.
////////
////////            2. **Purpose:** Clearly articulate the spiritual and emotional purpose of the Psalm, especially how it encourages or guides believers in worship, trust, or repentance.
////////
////////            3. **Themes:** Identify and support the Psalm's key themes (e.g., deliverance, divine justice, praise, lament, trust), citing specific verses.
////////
////////            4. **Theological and Christological Summary:** In one or two concise paragraphs, explain how the Psalm contributes to an understanding of God, covenant, sin, grace, and salvation, and highlight any direct or indirect references to Christ, the gospel, or messianic fulfillment (with supporting New Testament passages where appropriate).
////////
////////            5. **Framework and Literary Structure:** Identify structural patterns (e.g., lament-to-praise, parallelism, covenant appeals) and explain how these support the message of the Psalm.
////////
////////            6. **Memorable Quotes & Dual Interpretation:** Extract key verses or phrases from the Psalm and explain each twice:
////////               - For **believers**: as spiritual encouragement, theological depth, or worship guidance
////////               - For **non-believers**: as universal wisdom, poetic insight, or ethical reflection
////////
////////            7. **Real-World Application:** Offer practical, contemporary ways to apply the Psalm’s message, including illustrative case studies from personal experience, church history, or broader culture.
////////
////////            8. **Comparative Insight:** Reference other psalms that are thematically, structurally, or emotionally similar, with a short explanation of how they relate or differ.
////////
////////            9. **Audience Contextualization:** Explain how the Psalm’s message could be presented to believers, non-believers, or spiritually curious audiences, with attention to tone, relevance, and interpretive angle.
////////
////////            All responses should remain concise but thorough, typically organized in six paragraphs or an equivalent structured format. The tone should be respectful, theologically grounded, and accessible to a wide readership.
////////
////////            DO NOT ADD HEADERS.
////////            """)
////////        $psalm34Abstract.wrappedValue = response.content // If '.value' is not correct, use the actual property name that contains the String in LanguageModelSession.Response<String>
////////    } catch {
////////        psalm34Abstract = "Failed to generate abstract: \(error.localizedDescription)"
////////    }
////////}
////////
////////private func addItem() {
////////    withAnimation {
////////        let newItem = Item(timestamp: Date())
////////        modelContext.insert(newItem)
////////    }
////////}
////////
////////private func deleteItems(offsets: IndexSet) {
////////    withAnimation {
////////        for index in offsets {
////////            modelContext.delete(items[index])
////////        }
////////    }
////////}
////////}
////////
////////#Preview {
////////    ContentView()
////////        .modelContainer(for: Item.self, inMemory: true)
////////}
