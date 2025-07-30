//
//  ContentView.swift
//  ChatGPTCoreModel_playground
//
//  Created by Xcode Developer on 7/15/25.
//

import SwiftUI
import FoundationModels
import Combine
import Observation

// MARK: - Model for a single queued Psalm abstract
struct PsalmAbstract: Identifiable, Sendable {
    let id = UUID()
    let psalmNumber: Int
    var response: String = "Pending..."
    var isCompleted: Bool = false
}

// MARK: - Response Manager for Swift 6 Concurrency
actor ResponseManager {
    private var response: String = ""
    
    func updateResponse(_ newResponse: String) {
        response = newResponse
    }
    
    var currentResponse: String {
        response
    }
}

// MARK: - Psalm Processing Manager using only standard Swift features
@MainActor
class PsalmProcessingManager: ObservableObject {
    @Published var abstracts: [PsalmAbstract] = []
    private var psalmCache: String?
    
    // Use standard Swift Dictionary for task management instead of custom queue
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    
    // Throttling for UI updates
    private var lastUpdateTime = Date()
    private let updateInterval: TimeInterval = 0.1
    
    // Cancel all active tasks
    func cancelAllTasks() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
    
    deinit {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
    
    // Batch processing support
    func addMultiplePsalms(_ psalmNumbers: [Int]) async {
        // Add all psalms first
        let newAbstracts = psalmNumbers.map { PsalmAbstract(psalmNumber: $0) }
        abstracts.append(contentsOf: newAbstracts)
        
        // Process all psalms concurrently using TaskGroup
        await withTaskGroup(of: Void.self) { group in
            for abstract in newAbstracts {
                group.addTask { [weak self] in
                    await self?.runPsalmAbstract(abstract)
                }
            }
        }
    }
    
    func addSinglePsalm(_ psalmNumber: Int) async {
        let abstract = PsalmAbstract(psalmNumber: psalmNumber)
        abstracts.append(abstract)
        
        // Create and register task
        let task = Task<Void, Never> { [weak self] in
            
            await self?.runPsalmAbstract(abstract)
        }
        activeTasks[abstract.id] = task
    }
    
    private func updateAbstract(id: UUID, response: String, isCompleted: Bool) {
        if let index = abstracts.firstIndex(where: { $0.id == id }) {
            abstracts[index].response = response
            abstracts[index].isCompleted = isCompleted
        }
    }
    
    private func shouldThrottleUpdate() -> Bool {
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)
        if timeSinceLastUpdate >= updateInterval {
            lastUpdateTime = now
            return false
        }
        return true
    }
    
    private func runPsalmAbstract(_ abstract: PsalmAbstract) async {
        do {
            // Load psalm text (with caching)
            let allText = try await loadPsalmText()
            
            guard let psalm = psalmText(from: allText, number: abstract.psalmNumber) else {
                updateAbstract(id: abstract.id, response: "Error: Could not find Psalm \(abstract.psalmNumber) in the text file", isCompleted: true)
                return
            }
            
            // Create instructions
            let instructions = createInstructions(for: abstract.psalmNumber, psalm: psalm)
            let prompt = Prompt("Write an abstract for Psalm \(abstract.psalmNumber) per your instructions.")
            let model = SystemLanguageModel.default
            let session = LanguageModelSession(
                model: model,
                guardrails: .default,
                tools: [],
                instructions: instructions
            )
//            let session = LanguageModelSession(instructions: instructions)
            
            // Stream response with Swift 6 safe concurrency
            let stream = session.streamResponse(to: prompt, options: GenerationOptions(sampling: .greedy, temperature: 1.8, maximumResponseTokens: 8192))
            
            // Use an actor to manage the response state safely
            let responseManager = ResponseManager()

            for try await partial in stream {
                await responseManager.updateResponse(partial)
                let currentResponse = await responseManager.currentResponse
                updateAbstract(id: abstract.id, response: currentResponse, isCompleted: false)
            }
            
            // Final update
            let finalResponse = await responseManager.currentResponse
            if finalResponse.isEmpty {
                updateAbstract(id: abstract.id, response: "Error: Received empty response from language model", isCompleted: true)
            } else {
                updateAbstract(id: abstract.id, response: finalResponse, isCompleted: true)
                print("✅ Psalm \(abstract.psalmNumber) abstract completed successfully")
            }
            
        } catch {
            updateAbstract(id: abstract.id, response: "Error: \(error.localizedDescription)", isCompleted: true)
            print("❌ Error generating Psalm \(abstract.psalmNumber): \(error.localizedDescription)")
        }
        
        // Clean up task reference
        activeTasks.removeValue(forKey: abstract.id)
    }
    
    private func loadPsalmText() async throws -> String {
        // Cache the psalm text to avoid repeated file reads
        if let cached = psalmCache {
            return cached
        }
        
        guard let path = Bundle.main.path(forResource: "Psalms", ofType: "txt") else {
            throw NSError(domain: "PsalmLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find Psalms.txt file in bundle"])
        }
        
        let text = try String(contentsOfFile: path, encoding: .utf8)
        psalmCache = text
        return text
    }
    
    private func createInstructions(for psalmNumber: Int, psalm: String) -> Instructions {
        Instructions("""
            Your instructions:
            When prompted with a specific psalm (e.g., "Psalm 23" or "23"), you will write a six-paragraph abstract of psalm \(psalmNumber) by following the description for each paragraph.
            
            RESPOND IN PLAIN TEXT ONLY - DO NOT USE JSON, XML, OR ANY OTHER STRUCTURED FORMAT.
            
            Do not number the paragraphs or precede each paragraph with a topic summation; support every statement you write about the psalm with a reference to the verse(s), providing at least one quote for each paragraph.
            
            IMPORTANT: Cite your source for every sentence you write in every paragraph (include verse(s) or excerpt(s)).
            ALSO IMPORTANT: Cite the entire psalm before generating the abstract.
            
            1. The abstract should begin with a key highlight that best represents the central message or emphasis of the Psalm, reflecting its specific content and significance. Include at least one quote or citation from the psalm.
            2. Clearly describe the purpose of the Psalm, explaining its spiritual intent and how it serves or helps the believer. Avoid mentioning the writer unless referring to the Psalm's direct impact on worship or spiritual life.
            3. Identify and summarize the key themes found in the psalm, supported by references from the text itself.
            4. Provide a theological summary that explains how the psalm's message contributes to an understanding of God, faith, and spiritual matters.
            5. Write a Christological summary that identifies any direct or indirect connections to Christ, the gospel, or messianic prophecies.
            6. Draw direct parallels to Christian teachings, using New Testament scriptures to illustrate how the message of the psalm is fulfilled or mirrored in Christ and His teachings, and give advice on how Christians today can apply the psalm's lessons in their own lives.
            
            Write your response as continuous prose with clear paragraph breaks, not as structured data or JSON.
            
            Cite the full text of Psalm \(psalmNumber) before beginning your abstract:
            \(psalm)
            """)
    }
    
    private func psalmText(from fullText: String, number: Int) -> String? {
        guard (1...150).contains(number) else { return nil }
        let startMarker = "<<PSALM \(number)>>"
        guard let startRange = fullText.range(of: startMarker) else {
            return nil
        }
        let afterStart = startRange.upperBound..<fullText.endIndex
        let endMarker: String? = number < 150 ? "<<PSALM \(number + 1)>>" : nil
        
        let endIndex: String.Index
        if let next = endMarker,
           let nextRange = fullText.range(of: next, options: .literal, range: afterStart) {
            endIndex = nextRange.lowerBound
        } else {
            endIndex = fullText.endIndex
        }
        
        let snippet = fullText[startRange.lowerBound..<endIndex]
        return snippet.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Main View
struct ContentView: View {
    @State private var psalmNumber: Int = Int.random(in: 1 ... 150)
    @State private var psalmNumberInput: String = String()
    @StateObject private var processingManager = PsalmProcessingManager()
    
    // For batch processing
    @State private var showingBatchSheet = false
    @State private var batchStartNumber = 1
    @State private var batchEndNumber = 5
    
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
    
    // Timer properties for stepper acceleration
    @State private var timer: Timer?
    @State private var timerInterval: TimeInterval = 0.5
    @State private var isIncrementing: Bool = true
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, content: {
                HStack {
                    Text("PSALM ABSTRACT GENERATOR")
                        .font(.body)
                        .fontWeight(Font.Weight.bold)
                        .padding([.top, .horizontal])
                    
                    Spacer()
                    
                    // Batch processing button
                    Button(action: {
                        showingBatchSheet = true
                    }) {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundColor(Color(UIColor.white))
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                            .fontWeight(.medium)
                            .imageScale(.medium)
                    }
                    .padding(.trailing)
                }
                
                ZStack(alignment: (.trailing), content: {
                    HStack {
                        HStack {
                            Group {
                                Button(action: {
                                    decrementPsalm()
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(Color(UIColor.white))
                                        .symbolRenderingMode(.hierarchical)
                                        .font(.title)
                                        .fontWeight(.medium)
                                        .imageScale(.large)
                                        .labelStyle(.iconOnly)
                                        .clipShape(Circle())
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
                                .buttonStyle(PlainButtonStyle())
                                .shadow(color: Color.white.opacity(0.5), radius: 2, x: 0, y: 0)
                                
//                                // Number input field
//                                TextField("Psalm \(psalmNumber)", text: quotedPsalmNumberInput)
//                                    .keyboardType(.numberPad)
//                                    .multilineTextAlignment(.center)
//                                    .textFieldStyle(DefaultTextFieldStyle())
//                                    .font(.title)
//                                    .fontWeight(.semibold)
//                                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
//                                    .onChange(of: psalmNumberInput) { oldValue, newValue in
//                                        let filtered = newValue.filter { "0123456789".contains($0) }
//                                        if let value = Int(filtered) {
//                                            psalmNumber = min(max(value, 1), 150)
//                                        }
//                                        psalmNumberInput = "\(psalmNumber)"
//                                    }
//                                    .foregroundColor(Color(UIColor.white))
//                                    .background(Color(UIColor.clear))
                                
                                // Number input field with slide-to-change
                                TextField("Psalm \(psalmNumber)", text: quotedPsalmNumberInput)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(DefaultTextFieldStyle())
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
                                    .onChange(of: psalmNumberInput) { _, newValue in
                                        let filtered = newValue.filter { "0123456789".contains($0) }
                                        if let value = Int(filtered) {
                                            psalmNumber = min(max(value, 1), 150)
                                        }
                                        psalmNumberInput = "\(psalmNumber)"
                                    }
                                    .foregroundColor(Color(UIColor.white))
                                    .background(Color.clear)
                                    .gesture(
                                        DragGesture(minimumDistance: 10, coordinateSpace: .local)
                                            .onChanged { value in
                                                if value.translation.width > 0 {
                                                    incrementPsalm()    // slide right → increment
                                                } else if value.translation.width < 0 {
                                                    decrementPsalm()    // slide left → decrement
                                                }
                                            }
                                    )
                                
                                Button(action: {
                                    incrementPsalm()
                                }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(Color(UIColor.white))
                                        .symbolRenderingMode(.hierarchical)
                                        .font(.title)
                                        .fontWeight(.medium)
                                        .imageScale(.large)
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
                                .buttonStyle(PlainButtonStyle())
                                .shadow(color: Color.white.opacity(0.5), radius: 2, x: 0, y: 0)
                            }
                            .padding(4)
                        }
                        .background(Color.init(uiColor: UIColor(white: 1.0, alpha: 0.1)))
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25), style: .continuous))
                        .padding(.trailing, 75)
                    }
                    
                    Button {
                        dismissKeyboard()
                        Task {
                            await processingManager.addSinglePsalm(psalmNumber)
                        }
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(Color(UIColor.white))
                            .symbolRenderingMode(.hierarchical)
                            .font(.title)
                            .fontWeight(.medium)
                            .imageScale(.large)
                            .labelStyle(.iconOnly)
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25), style: .continuous))
                    }
                    .padding()
                    .glassEffect(in: .rect(cornerRadius: 25.0))
                })
                .ignoresSafeArea()
                
                
                GeometryReader { geometryProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(processingManager.abstracts) { item in
                                let jsonResponse = removeJSONTags(item.response)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Psalm \(item.psalmNumber)")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .frame(idealWidth: geometryProxy.size.width, maxWidth: geometryProxy.size.width)
                                        .padding()
                                        .glassEffect(in: .rect(cornerRadius: 25.0))
                                    
                                    if item.isCompleted {
                                        Text(jsonResponse)
                                            .focusEffectDisabled(false)
                                            .focusable(true)
                                            .textSelection(.enabled)
                                            .dynamicTypeSize(DynamicTypeSize.medium)
                                            .font(.body)
                                            .padding()
                                            .frame(idealWidth: geometryProxy.size.width, maxWidth: geometryProxy.size.width)
                                    } else {
                                        // Show streaming text even when not completed
                                        if !jsonResponse.isEmpty && jsonResponse != "Pending..." {
                                            Text(jsonResponse)
                                                .focusEffectDisabled(false)
                                                .focusable(true)
                                                .textSelection(.enabled)
                                                .dynamicTypeSize(DynamicTypeSize.medium)
                                                .font(.body)
                                                .padding()
                                                .frame(idealWidth: geometryProxy.size.width, maxWidth: geometryProxy.size.width)
                                        } else {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .frame(idealWidth: geometryProxy.size.width, maxWidth: geometryProxy.size.width)
                                        }
                                    }
                                }
                                .padding()
                                .frame(idealWidth: geometryProxy.size.width, maxWidth: geometryProxy.size.width)
                                .glassEffect(in: .rect(cornerRadius: 25.0))
                            }
                        }
                    }
                    
                }
            })
            .onAppear {
                psalmNumberInput = "\(psalmNumber)"
            }
            .padding(.bottom, 75.0)
            .sheet(isPresented: $showingBatchSheet) {
                BatchProcessingSheet(
                    startNumber: $batchStartNumber,
                    endNumber: $batchEndNumber,
                    onProcess: { start, end in
                        Task {
                            let numbers = Array(start...end)
                            await processingManager.addMultiplePsalms(numbers)
                        }
                    }
                )
            }
            
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, content: {
                    
                    Text("James Alan Bush")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Commit ID 7fe5119")
                        .font(.caption)
                        .fontWeight(.light)
                        .foregroundColor(.secondary)
                    
                    
                })
                .padding()
                .frame(idealWidth: .infinity, maxWidth: .infinity)
                .glassEffect(in: .rect(cornerRadius: 25.0))
            }
            .padding(.horizontal)
        }
        .background {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primary.opacity(0.75),
                    Color.accentColor.opacity(0.25)
                ]),
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
            .ignoresSafeArea()
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func psalmText(from fullText: String, number: Int) -> String? {
        guard (1...150).contains(number) else { return nil }
        let startMarker = "<<PSALM \(number)>>"
        guard let startRange = fullText.range(of: startMarker) else {
            return nil
        }
        let afterStart = startRange.upperBound..<fullText.endIndex
        let endMarker: String? = number < 150 ? "<<PSALM \(number + 1)>>" : nil
        
        let endIndex: String.Index
        if let next = endMarker,
           let nextRange = fullText.range(of: next, options: .literal, range: afterStart) {
            endIndex = nextRange.lowerBound
        } else {
            endIndex = fullText.endIndex
        }
        
        let snippet = fullText[startRange.lowerBound..<endIndex]
        return snippet.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func removeJSONTags(_ input: String) -> String {
        // Pattern to match JSON keys (tags) - quoted strings followed by a colon
        var result = input
        
        // Remove JSON keys/tags and replace with newline
        // This pattern matches "tagname": including the quotes and colon
        result = result.replacingOccurrences(of: "\"[^\"]*\"\\s*:", with: "\n\n", options: .regularExpression)
        
        // Remove the JSON structure characters (but keep the content)
        result = result.replacingOccurrences(of: "[{}\\[\\],]", with: "", options: .regularExpression)
        
        // Remove quotes around values
        result = result.replacingOccurrences(of: "\"", with: "")
        
        // Clean up multiple spaces (but preserve newlines)
        result = result.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        
        // Clean up multiple newlines (reduce to maximum of 2)
        result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Trim leading/trailing whitespace from each line
        let lines = result.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Join lines, removing completely empty ones but preserving single newlines
        var finalLines: [String] = []
        for i in 0..<lines.count {
            if !lines[i].isEmpty || (i > 0 && !lines[i-1].isEmpty) {
                finalLines.append(lines[i])
            }
        }
        
        return finalLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
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
}

// MARK: - Batch Processing Sheet
struct BatchProcessingSheet: View {
    @Binding var startNumber: Int
    @Binding var endNumber: Int
    let onProcess: (Int, Int) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Process Multiple Psalms")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Start Psalm:")
                    Stepper(value: $startNumber, in: 1...150) {
                        Text("\(startNumber)")
                            .font(.title2)
                    }
                    
                    Text("End Psalm:")
                    Stepper(value: $endNumber, in: 1...150) {
                        Text("\(endNumber)")
                            .font(.title2)
                    }
                }
                .padding()
                
                Text("This will process \(max(0, endNumber - startNumber + 1)) psalms concurrently")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Process") {
                        if startNumber <= endNumber {
                            onProcess(startNumber, endNumber)
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(startNumber > endNumber)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
