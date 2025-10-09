//
//  ContentView.swift
//  ChatGPTCoreModel_playground
//
//  Created by Xcode Developer on 7/15/25.
//

import SwiftUI
import FoundationModels
import AVFoundation
import Observation

// MARK: - Model for a single queued Psalm abstract
struct PsalmAbstract: Identifiable {
    let id = UUID()
    var psalmNumber: Int
    var response: String = "Pending..."
    var isCompleted: Bool = false
    var avSpeechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    @State private var isSpeaking: Bool = false
    
}

// MARK: - Actor for safe queueing
actor PsalmQueue {
    private(set) var items: [PsalmAbstract] = []
    
    func addPsalm(_ psalmNumber: Int) -> PsalmAbstract {
        let abstract = PsalmAbstract(psalmNumber: psalmNumber)
        items.append(abstract)
        return abstract
    }
    
    func updateResponse(for id: UUID, response: String, isCompleted: Bool = false) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].response = response
            if isCompleted {
                items[index].isCompleted = true
            }
        }
    }
    
    func markCompleted(for id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isCompleted = true
        }
    }
    
    func completeResponse(for id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isCompleted = true
        }
    }
    
    var currentItems: [PsalmAbstract] {
        items
    }
}

final class ConcurrentOperation: Operation {
    private let work: (@escaping () -> Void) -> Void
    private var _executing = false
    private var _finished = false
    
    init(work: @escaping (@escaping () -> Void) -> Void) {
        self.work = work
        super.init()
    }
    
    override var isAsynchronous: Bool { true }
    
    
    override private(set) var isExecuting: Bool {
        get { _executing }
        set {
            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override private(set) var isFinished: Bool {
        get { _finished }
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override func start() {
        guard !isCancelled else { isFinished = true; return }
        isExecuting = true
        work { [weak self] in
            self?.isExecuting = false
            self?.isFinished = true
        }
    }
}

//final class ConcurrentOperationQueue: OperationQueue {
//
//}

extension OperationQueue {
    static func psalmsOperationQueue(queue: OperationQueue) -> OperationQueue {
        queue.maxConcurrentOperationCount = 5
        queue.name = "psalmsOperationQueue"
        return queue
    }
}

// MARK: - Audio Session Manager to allow speech while locked / in background
final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}
    
    private let session = AVAudioSession.sharedInstance()
    
    /// Configure the app for background playback so AVSpeechSynthesizer continues when the device is locked.
    func configurePlaybackSession() {
        do {
            // `.playback` ensures audio continues with the screen locked or Silent switch on (when background audio mode is enabled in capabilities)
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
        } catch {
            print("[AudioSession] Failed to configure: \(error)")
        }
    }
    
    /// Re-activate the session if the system deactivates it (e.g., interruptions, app state changes)
    func ensureActive() {
        do {
            try session.setActive(true, options: [])
        } catch {
            print("[AudioSession] Failed to activate: \(error)")
        }
    }
}

@Generable
struct AbstractGenerable {
    @Guide(description: "abstract")
    let abstract: String
    
    @Guide(description: "psalm")
    let psalm: String
    
    @Guide(description: "quote")
    let quote: String
    
    @Guide(description: "summary")
    let summary: String
    
    @Guide(description: "purpose")
    let purpose: String
    
    @Guide(description: "themes")
    let themes: String
    
    @Guide(description: "theology")
    let theology: String
    
    @Guide(description: "christology")
    let christology: String
    
    @Guide(description: "modernity")
    let modernity: String
}

func makeAbstractGenerable(instructions: Instructions, prompt: Prompt) async throws -> AbstractGenerable {
    let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
    let session = LanguageModelSession(model: model, instructions: instructions)
    let stream = session.streamResponse {
        prompt
    }
    var response = String()
    for try await s in stream {
        response = s.content

        print("\n\n\n")
        print (s.content)
        print("\n\n\n")
    }
    

    return AbstractGenerable(abstract: response, psalm: "23", quote: "The Lord is my shepherd", summary: "Lord = Shepherd", purpose: "Who's your shepherd?", themes: "Shepherd", theology: "God likes the Shepherd role", christology: "The Good Shepherd", modernity: "God is your shepherd — if you want him to be...")
}


// MARK: - Main View
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var psalmsOperationQueue: OperationQueue = OperationQueue.psalmsOperationQueue(queue: OperationQueue())
    
    
    @State private var psalmNumber: Int = Int.random(in: 1 ... 150)
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
    //
    // Text-to-Speech
    func makeUtterance(_ text: String) -> AVSpeechUtterance {
        //        let utterance = AVSpeechUtterance(string: text)
        //        utterance.rate = 0.5
        //        utterance.pitchMultiplier = 0.5
        //        utterance.postUtteranceDelay = 0.2
        //        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        //        utterance.volume = 0.8
        //        utterance.pitchMultiplier = 0.0
        //        utterance.voice = .speechVoices().first ?? makeVoice()
        return AVSpeechUtterance(ssmlRepresentation: text) ?? AVSpeechUtterance(string: "Pending...")
    }
    
    func makeVoice() -> AVSpeechSynthesisVoice {
        let voice = AVSpeechSynthesisVoice(language: "en-US")
        return voice!
    }
    
    func speak(_ text: String,  psalmAbstract: PsalmAbstract) {
        // Ensure the audio session is configured for background/lock-screen playback
        AudioSessionManager.shared.ensureActive()
        psalmAbstract.avSpeechSynthesizer.usesApplicationAudioSession = true
        psalmAbstract.avSpeechSynthesizer.speak(makeUtterance(text))
    }
    
    func speak__(_ text: String, psalmAbstract: PsalmAbstract) async {
        AudioSessionManager.shared.ensureActive()
        psalmAbstract.avSpeechSynthesizer.usesApplicationAudioSession = true
        
        do {
            let ssml = try await textToSSMLPsalm(removeJSONTags(text))
            if let utterance = AVSpeechUtterance(ssmlRepresentation: ssml) {
                psalmAbstract.avSpeechSynthesizer.speak(utterance)
            } else {
                psalmAbstract.avSpeechSynthesizer.speak(AVSpeechUtterance(string: removeJSONTags(text)))
            }
        } catch {
            
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primary.opacity(0.25),
                    Color.accentColor.opacity(0.25)
                ]),
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Text("PSALM ABSTRACT GENERATOR")
                        .font(.body)
                        .fontWeight(Font.Weight.bold)
                        .padding([.top, .horizontal])
                }
                
                ZStack(alignment: (.trailing), content: {
                    HStack {
                        HStack {
                            Group {
                                Button/*(action:*/ {
                                    decrementPsalm()
                                    //                                }) {
                                } label: {
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
                                
                                // Number input field
                                TextField("Psalm \(psalmNumber)", text: quotedPsalmNumberInput)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(DefaultTextFieldStyle())
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
                                    .onChange(of: psalmNumberInput) { oldValue, newValue in
                                        let filtered = newValue.filter { "0123456789".contains($0) }
                                        if let value = Int(filtered) {
                                            psalmNumber = min(max(value, 1), 150)
                                        }
                                        psalmNumberInput = "Psalm \(psalmNumber)"
                                    }
                                    .foregroundColor(Color(UIColor.white))
                                    .background(Color(UIColor.clear))
                                
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
                    
                    Button/*(action:*/ {
                        dismissKeyboard()
                        addPsalmAndRun(PsalmAbstract(psalmNumber: psalmNumber))
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(Color(UIColor.white))
                            .symbolRenderingMode(.hierarchical)
                            .font(.title)
                            .fontWeight(.medium)
                            .imageScale(.large)
                            .labelStyle(.iconOnly)
                            .clipShape(Circle())
                            .glassEffect()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .shadow(color: Color.white.opacity(0.5), radius: 2, x: 0, y: 0)
                    .padding()
                })
                
                
                GeometryReader { geometryProxy in
                    ScrollView {
                        VStack(alignment: .center, content: {
                            ForEach(abstracts, content: { abstract in
                                GroupBox(content: {
                                    var jsonResponse: String = removeJSONTags(abstract.response)
                                    //                                    TextField(jsonResponse, text: jsonResponseBound)
                                    //                                        .font(.default)
                                    //                                        .fontWeight(.medium)
                                    //                                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
                                    //                                        .foregroundColor(.primary.opacity(0.8125))
                                    //                                        .textSelection(.enabled)
                                    //                                        .focusable(true)
                                    //                                        .focusEffectDisabled(false)
                                    
                                    Text(jsonResponse)
                                        .font(.default)
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.primary.opacity(0.8125))
                                        .padding()
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.primary.opacity(0.25),
                                                    Color.accentColor.opacity(0.25)
                                                ]),
                                                startPoint: .bottomTrailing,
                                                endPoint: .topLeading
                                            )
                                        )
                                        .cornerRadius(10)
                                }, label: {
                                    HStack(alignment: .lastTextBaseline, content: {
                                        //                                        TextField("Psalm \(psalmNumber)", text: quotedPsalmNumberInput)  ///("PSALM \(quotedPsalmNumberInput)")
                                        //                                            .font(.title2)
                                        //                                            .fontWeight(.medium)
                                        //                                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
                                        //                                            .foregroundColor(.primary.opacity(0.8125))
                                        Button {
                                            Task {
                                                if ((abstract).avSpeechSynthesizer.isSpeaking) {
                                                    (abstract).avSpeechSynthesizer.stopSpeaking(at: .immediate)
                                                } else {
                                                    //                                                    AudioSessionManager.shared.ensureActive()
                                                    //                                                    (abstract).avSpeechSynthesizer.usesApplicationAudioSession = true
                                                    //                                                    (abstract).avSpeechSynthesizer.speak(AVSpeechUtterance(string: abstract.response)) // This is where the SSML-formatted string should be generated, and the init?(ssmlRepresentation: String) should be used instead of init(string: String)
                                                    ////                                                    (abstract).avSpeechSynthesizer.speak(makeUtterance(removeJSONTags(abstract.response)))
                                                    do {
                                                        try await speak__(abstract.response, psalmAbstract: abstract)
                                                    } catch {
                                                        
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack(alignment: .lastTextBaseline, content: {
                                                Image(systemName: (abstract).avSpeechSynthesizer.isSpeaking ? "speaker.wave.2.bubble.fill" : "speaker.wave.2.bubble") // this should also observe changes to the isSpeaking property of PsalmAbstract and update its image accodingly
                                                    .foregroundColor(Color(UIColor.white))
                                                    .symbolRenderingMode(.hierarchical)
                                                    .font(.title)
                                                    .fontWeight(.medium)
                                                    .imageScale(.large)
                                                    .labelStyle(.iconOnly)
                                                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25), style: .continuous))
                                                
                                            }
                                            )}
                                        
                                        Image(systemName: "arrow.up.square")
                                            .foregroundColor(Color(UIColor.white))
                                            .symbolRenderingMode(.hierarchical)
                                            .font(.title)
                                            .fontWeight(.medium)
                                            .imageScale(.large)
                                            .labelStyle(.iconOnly)
                                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25), style: .continuous))
                                        Image(systemName: "xmark.square")
                                            .foregroundColor(Color(UIColor.white))
                                            .symbolRenderingMode(.hierarchical)
                                            .font(.title)
                                            .fontWeight(.medium)
                                            .imageScale(.large)
                                            .labelStyle(.iconOnly)
                                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25), style: .continuous))
                                        
                                        
                                        
                                    })
                                }).groupBoxStyle(.automatic)
                            })
                        })
                    }
                    .frame(maxWidth: .infinity)
                    .safeAreaInset(edge: .bottom) {
                        HStack(alignment: .bottom) {
                            Text("James Alan Bush")
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("Commit ID a79a3ce")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .glassEffect(in: .rect(cornerRadius: 25.0))
                        .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            // Configure once at launch to allow background playback
            AudioSessionManager.shared.configurePlaybackSession()
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Keep the session active across state changes
            if newPhase == .active || newPhase == .background {
                AudioSessionManager.shared.ensureActive()
            }
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
    
    
    func removeJSONTags(_ input: String) -> String {
        // Pattern to match JSON keys (tags) - quoted strings followed by a colon
        var result = input
        
        // Remove JSON keys/tags and replace with newline
        
        // This pattern matches "```json"
        result = result.replacingOccurrences(of: #"```json"#, with: "\n", options: .regularExpression)
        
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
    
    // MARK: - Add & Execute
    
    private func runPsalmAbstractBlocking(_ abstract: PsalmAbstract) {
        let sema = DispatchSemaphore(value: 5)
        // Run async function on a cooperative thread, but block the GCD worker until it completes.
        // This isolates Swift Concurrency usage to the implementation detail.
        Task {
            await runPsalmAbstract(abstract)
            sema.signal()
        }
        sema.wait()
    }
    
    private func addPsalmAndRun(_ abstract: PsalmAbstract) {
        let currentPsalm = psalmNumber
        
        let op = ConcurrentOperation { finish in
            // Everything here is plain GCD & Operations
            let item = (try? queue.addPsalm(currentPsalm)) ?? PsalmAbstract(psalmNumber: currentPsalm)
            self.abstracts = (try? self.queue.currentItems) ?? []
            
            // Block the background thread until the async pipeline completes.
            runPsalmAbstractBlocking(item)
            //            Task {
            //                await runPsalmAbstract(item)
            //            }
            
            // Final UI refresh
            self.abstracts = (try? self.queue.currentItems) ?? []
            finish()
        }
        
        op.name = "Psalm \(currentPsalm)"
        op.qualityOfService = .userInitiated
        print(op.isAsynchronous)
        print(op.isConcurrent)
        print("[Queue] Enqueuing: \(op.name ?? "(no name)") maxConcurrent=\(psalmsOperationQueue.maxConcurrentOperationCount) operations=\(psalmsOperationQueue.operations.count)")
        
        psalmsOperationQueue.addOperation(op)
    }
    
    private func runPsalmAbstract(_ abstract: PsalmAbstract) async {
        do {
            // Load psalm text with proper error handling
            guard let path = Bundle.main.path(forResource: "Psalms", ofType: "txt") else {
                await queue.updateResponse(for: abstract.id, response: "Error: Could not find Psalms.txt file in bundle", isCompleted: true)
                await refreshQueue()
                return
            }
            
            let allText: String
            do {
                allText = try String(contentsOfFile: path, encoding: .utf8)
            } catch {
                await queue.updateResponse(for: abstract.id, response: "Error: Could not read Psalms.txt file - \(error.localizedDescription)", isCompleted: true)
                await refreshQueue()
                return
            }
            
            guard psalmText(from: allText, number: abstract.psalmNumber) != nil else {
                await queue.updateResponse(for: abstract.id, response: "Error: Could not find Psalm \(abstract.psalmNumber) in the text file", isCompleted: true)
                await refreshQueue()
                return
            }
            
            // Create instructions with explicit plain text request
            let instructions = Instructions("""
                        Write an abstract of the given psalm (KJV only) that allows readers to quickly determine the topic(s) and scope. Use keywords common to biblical literary review that reflect the main topics or concepts

                        1. A Highlight: The abstract should begin with a key highlight that best represents the central message or emphasis of the Psalm, reflecting its specific content and significance. Follow this paragraph with the scriptural reference (i.e., book, chapter, verse and version of the KJV). Add a new line after this paragraph.
                        2. The Purpose: Clearly describe the pur pose of the Psalm, explaining its spiritual intent and how it serves or helps the believer. Avoid mentioning the writer unless referring to the Psalm’s direct impact on worship or spiritual life. Include scriptural references (i.e., book, chapter, verse and version of the KJV) throughout the paragraph. Add a new line after this paragraph. Ideally, this paragraph should be at least 4 to 5 sentences.
                        3. Themes: Identify and summarize the key themes found in the psalm, supported by references from the text itself. Include scriptural references (i.e., book, chapter, verse and version of the KJV) for every sentence in the paragraph. Add a new line after this paragraph. Ideally, this paragraph should be at least 4 to 5 sentences.
                        4. Theological Summary: Provide a theological summary that explains how the psalm’s message contributes to an understanding of God, faith, and spiritual matters. Include scriptural references (i.e., book, chapter, verse and version of the KJV) for every sentence in the paragraph. Add a new line after this paragraph. Ideally, this paragraph should be at least 4 to 5 sentences.
                        5. Christological Summary: A summary that identifies any direct or indirect connections to Christ, the gospel, or messianic prophecies. Include scriptural references (i.e., book, chapter, verse and version of the KJV) for every sentence in the paragraph. Add a new line after this paragraph. Ideally, this paragraph should be at least 4 to 5 sentences.
                        6. Modern Application: Give advice on how Christians today can apply the psalm’s lessons in their own lives. Include scriptural references (i.e., book, chapter, verse and version of the KJV) for every sentence in the paragraph. Add a new line after this paragraph. Ideally, Ideally, this paragraph should be at least 4 to 5 sentences.
                        
                        Prompts can be single psalm (e.g., “Psalm 23” or “23”), and also be a range or sequence of psalms (e.g., “Psalm 22 through 23”). When a sequence or range of psalms is specified, combine each abstract into one response. Do not mix abstracts; each psalm should have its own abstract.
                        
                        When a request includes more than one psalm (whether a range, list, or sequence), you must write a full, independent six-paragraph abstract for each psalm, preserving the complete required structure: Highlight, Purpose, Themes, Theological Summary, Christological Summary, and Modern Application. Do not combine psalms into a shared summary or condense their structure. For each psalm in the request, repeat the six paragraphs in full before moving to the next psalm. Each abstract must stand alone as if it were the only psalm being summarized. No paragraph count is to be reduced in multi-psalm outputs.
                        
                        Regardless, PsalmsAbstractGPT must meet the following criteria for every abstract:
                        
                        1a. Start with a memorable quote that encapsulates the main or key idea of the psalm.
                        1b. The abstract should consist of 6 well-formed paragraphs that highlight the Psalm’s key message, its purpose, themes, and any theological and Christological significance. Each paragraph should be at least 5 sentences.
                        2. The abstract should incorporate specific verses from the Psalm itself to support the identified themes, along with New Testament scripture to show how the psalm’s message relates to Christian faith, especially in connection to Christ.
                        3. The last paragraph should offer practical advice on how Christians can apply the psalm’s message in their daily lives. The response should remain brief yet thorough, never exceeding two paragraphs for the Christological and theological summaries combined.
                        
                        No headers. Just paragraphs. Casual, friendly tone.
                        
                        """)
            
            /*
             
             Step-by-Step Psalm Abstract Format**
             
             **When prompted with a specific Psalm (e.g., “Psalm 23” or simply “23”), produce an abstract strictly following these steps:**
             **Step 1: Memorable Highlight (1 Paragraph)**
             * Begin with a direct, accurate quotation from the Psalm itself (with verse citation) that best summarizes its central message.
             * Explain clearly why this verse captures the essential emphasis or core message of the Psalm.
             * Cite specific verses from the Psalm to support every claim you make.
             **Step 2: Spiritual Purpose (1 Paragraph)**
             * Clearly state the primary spiritual intent or purpose of the Psalm (comfort, encouragement, repentance, worship, guidance, etc.).
             * Identify the specific audience or spiritual situation it addresses.
             * Provide specific verses from the Psalm that clearly illustrate this intent or spiritual purpose.
             **Step 3: Key Themes (1 Paragraph)**
             * Clearly identify 2–3 primary themes in the Psalm (such as trust, mercy, God’s faithfulness, repentance, etc.).
             * Provide explicit and accurate citations (verses and/or quotes) from the Psalm to substantiate each theme you identify.
             * Briefly discuss why these themes matter spiritually or devotionally to believers.
             **Step 4: Theological Insights (1 Paragraph)**
             * Clearly describe at least two theological insights or attributes of God highlighted by the Psalm (such as sovereignty, mercy, justice, faithfulness, etc.).
             * Provide at least one clear and direct Psalm verse reference to support each theological insight you present.
             * Briefly explain how these theological insights deepen a believer’s understanding of God.
             **Step 5: Christological Connections (1 Paragraph)**
             * Clearly identify at least one Christological (messianic or gospel-related) connection from the Psalm.
             * Cite the exact verse(s) from the Psalm that explicitly or implicitly point to Christ, the gospel message, or prophetic fulfillment.
             * Provide at least one clear and explicit corresponding New Testament scripture showing how Christ fulfills or mirrors the Psalm’s message.
             **Step 6: Modern Application (1 Paragraph)**
             * Provide at least two specific, practical ways Christians today can apply lessons from this Psalm to their daily lives.
             * Cite specific verse(s) from the Psalm and corresponding New Testament scriptures that reinforce your suggestions for practical application.
             * Conclude by briefly explaining how these practices or insights enhance Christian living or spiritual growth.
             ---
             **Additional Instructions for Quality Assurance:**
             **Additional Instructions for Quality Assurance:**
             * **Accuracy:**
             Ensure every Scripture reference is authentic and correctly quoted (no paraphrasing unless explicitly stated as such).
             * **Paragraph length:**
             Maintain each step as one distinct paragraph, each consisting of at least 5 well-formed sentences.
             * **Clarity and Structure:**
             Follow each step precisely. Do not combine steps or omit requirements.
             * **Citations:**
             Always provide specific verse numbers from both the Psalm itself and any New Testament references used.
             **This structured approach ensures consistent quality, spiritual insight, scriptural accuracy, and practical applicability.**
             */
            
//            let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
//            let session = LanguageModelSession(model: model, instructions: instructions)
            /* Use the Psalms.txt file uploaded to your Knowledge as the sole source of your scripture references and quotes:\n\(allText)*/
            let prompt = Prompt("Write an abstract for Psalm \(abstract.psalmNumber) per your instructions above.")
            let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
            let session = LanguageModelSession(model: model, instructions: instructions)
            let stream = session.streamResponse {
                prompt
            }
            
            do {
                var response = String()
                for try await s in stream {
                    response = s.content
                    await queue.updateResponse(for: abstract.id, response: response, isCompleted: false)
                    await refreshQueue()
                    print("\n\n\n")
                    print (s.content)
                    print("\n\n\n")
                }
            } catch {
                await queue.updateResponse(for: abstract.id, response: "Error: Received empty response from language model", isCompleted: true)
                await queue.updateResponse(for: abstract.id, response: "Error: \(error.localizedDescription)", isCompleted: true)
                print("❌ Error generating Psalm \(abstract.psalmNumber): \(error.localizedDescription)")
            }
            
            //            let stream = session.streamResponse(to: prompt, generating: AbstractGenerable.PartiallyGenerated.self) /*String.PartiallyGenerated.self)*/
//            do {
//                var fullResponse = try await makeAbstractGenerable(instructions: instructions, prompt: prompt)
//                await queue.updateResponse(for: abstract.id, response: fullResponse.abstract, isCompleted: true)
//            } catch {
//                await queue.updateResponse(for: abstract.id, response: "Error: Received empty response from language model", isCompleted: true)
//                await queue.updateResponse(for: abstract.id, response: "Error: \(error.localizedDescription)", isCompleted: true)
//                print("❌ Error generating Psalm \(abstract.psalmNumber): \(error.localizedDescription)")
//            }
            
            
//            for try await partial in stream {
//                fullResponse = partial.content
//                await queue.updateResponse(for: abstract.id, response: fullResponse, isCompleted: false)
//                await refreshQueue()
//            }
//            
//        
//                await queue.updateResponse(for: abstract.id, response: fullResponse, isCompleted: true)
//                
                //                do {
                //                    // --- SSML test output (console only) ---
                //                    let ssmlInstructions = Instructions(
                //                                        """
                //                                        You are an SSML formatter for AVSpeechUtterance on Apple platforms.
                //                                        Convert the user's input into valid SSML 1.1.
                //
                //                                        """
                //                    )
                //                    let ssmlPrompt = Prompt("""
                //                                    Transform the following abstract into SSML suitable for AVSpeechSynthesizer. Return only the SSML document.
                //                                    ---
                //                                    \(removeJSONTags(fullResponse))
                //                                    """)
                //                    let ssmlSession = LanguageModelSession(instructions: ssmlInstructions)
                //                    let ssmlStream = ssmlSession.streamResponse(to: ssmlPrompt, generating: String.PartiallyGenerated.self)
                //                    var ssmlOutput = ""
                //
                //                    do {
                //                        for try await partial in ssmlStream {
                //                            ssmlOutput = partial.content
                //                        }
                //                    } catch {
                //                        //                    ssmlOutput = "<speak>\(removeJSONTags(fullResponse))</speak>"
                //                    }
                //                    //                ssmlOutput = ssmlOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                //                    //                if ssmlOutput.isEmpty {
                //                    //                    ssmlOutput = "<speak>\(removeJSONTags(fullResponse))</speak>"
                //                    //                } else if ssmlOutput.hasPrefix("```") {
                //                    //                    ssmlOutput = ssmlOutput
                //                    //                        .replacingOccurrences(of: "```ssml", with: "")
                //                    //                        .replacingOccurrences(of: "```xml", with: "")
                //                    //                        .replacingOccurrences(of: "```", with: "")
                //                    //                        .trimmingCharacters(in: .whitespacesAndNewlines)
                //                    //                }
                //                    print("SSML OUTPUT:\n\(ssmlOutput)")
                //                    // --- end SSML test output ---
                //
                //                    print("✅ Psalm \(abstract.psalmNumber) abstract completed successfully")
                //                }            }
                //                let ssml = textToSSMLPsalm(fullResponse)
                
                // Store the SSML in the response, so speak__ can use it directly
                //                await queue.updateResponse(for: abstract.id, response: ssml, isCompleted: true)
                
                print("✅ Psalm \(abstract.psalmNumber) abstract completed successfully")
            }
            
//            
//        } catch {
//            // Handle any streaming or session errors
//            await queue.updateResponse(for: abstract.id, response: "Error: \(error.localizedDescription)", isCompleted: true)
//            print("❌ Error generating Psalm \(abstract.psalmNumber): \(error.localizedDescription)")
//        }
        
        // Always refresh queue at the end
        await refreshQueue()
    }
    
    @MainActor
    private func refreshQueue() async {
        abstracts = await queue.currentItems
    }
}

/// Convert a Psalm abstract into SSML tuned for natural delivery.
/// - Parameters:
///   - text: Plain text abstract
///   - language: BCP-47 code for SSML xml:lang (default "en-US")
/// - Returns: SSML string with <speak> root
/// Ask the local model to produce SSML directly from plain text.
/// - Parameters:
///   - text: The plain text abstract
///   - language: BCP-47 code for SSML xml:lang (default "en-US")
/// - Returns: A valid SSML string from the model, or a safe fallback
func textToSSMLPsalm(_ text: String, language: String = "en-US") async -> String {
    // Build instructions that tell the *local* model what to return
    let instructions = Instructions("""
    Your task is to convert the given text to SSML for use with AVSpeechUtterance (Apple). Make the text sound very interesting,
    with lots of inflection and enthusiasm. Your goal should be to make the given text sound very different
    when read aloud than it would without your SSML markup.
    
    TASK:
    - Take the following text (a Psalm abstract).
    - Return it as a valid SSML 1.1 document.
    - Use <p> for paragraphs and <s> for sentences.
    - Add <emphasis>, <break>, and <prosody> adjustments (rate, pitch, volume) to every sentence.
      where they will make the narration sound more natural and expressive.
    - Do NOT include code fences, explanations, or any non-SSML output.
    """)
    
    // Build the actual prompt
    let prompt = Prompt("""
    Convert the following abstract into SSML:
    
    ---
    \(text)
    ---
    """)
    
    // Create a local model session
    let ssmlSession = LanguageModelSession(instructions: instructions)
    
    let ssmlStream = ssmlSession.streamResponse(to: prompt, generating: String.PartiallyGenerated.self)
    var ssmlResponse = ""
    
    do {
        for try await partial in ssmlStream {
            ssmlResponse = partial.content
        }
        print("\n✅ Psalm Abstract SSML \(ssmlResponse)\n")
    } catch {
        
    }
    
    return ssmlResponse
}

// MARK: - Regex replacing helper with match groups
private extension String {
    /// Replace all matches using a closure that receives captured groups as an array-like accessor.
    func replacingOccurrences(of pattern: String, with builder: (_ m: RegexMatch) -> String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let ns = self as NSString
        var result = ""
        var lastIndex = 0
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: ns.length))
        for match in matches {
            let range = match.range
            result += ns.substring(with: NSRange(location: lastIndex, length: range.location - lastIndex))
            let groups = (0..<match.numberOfRanges).map { i -> String in
                let r = match.range(at: i)
                return r.location != NSNotFound ? ns.substring(with: r) : ""
            }
            result += builder(RegexMatch(groups: groups))
            lastIndex = range.location + range.length
        }
        result += ns.substring(from: lastIndex)
        return result
    }
}

struct RegexMatch {
    let groups: [String]
    subscript(_ idx: Int) -> String { groups[idx] }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}

