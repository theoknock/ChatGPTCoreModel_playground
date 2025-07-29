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

// MARK: - Main View
struct ContentView: View {
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
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, content: {
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
                                        psalmNumberInput = "\(psalmNumber)"
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
                    
                    Button {
                        dismissKeyboard()
                        addPsalmAndRun()
                    } label: {
                        Image(systemName: "pencil")
//                            .padding(8)
                            .foregroundColor(Color(UIColor.white))
                            .symbolRenderingMode(.hierarchical)
                            .font(.title)
                            .fontWeight(.medium)
                            .imageScale(.large)
                            .labelStyle(.iconOnly)
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25), style: .continuous))
//                            .glassEffect()
//                            .foregroundColor(Color(UIColor.white))
//                            .symbolRenderingMode(.monochrome)
//                            .font(.largeTitle)
//                            .imageScale(.medium)
//                            .labelStyle(.iconOnly)
//                            .clipShape(Circle())
                    }
                    .padding()
                    .glassEffect(in: .rect(cornerRadius: 25.0))
                })
                .ignoresSafeArea()
                
                
                GeometryReader { GeometryProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(abstracts) { item in
                                let jsonResponse = removeJSONTags(item.response)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Psalm \(item.psalmNumber)")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .frame(idealWidth: GeometryProxy.size.width, maxWidth: GeometryProxy.size.width)
                                        .padding()
                                        .glassEffect(in: .rect(cornerRadius: 25.0))
                                    
                                    if item.isCompleted {
                                        Text(jsonResponse)
                                            .focusEffectDisabled(false)
                                            .textSelection(.enabled)
                                            .focusable(true)
                                            .dynamicTypeSize(DynamicTypeSize.xSmall)
                                            .font(.body)
                                            .padding()
                                            .frame(idealWidth: GeometryProxy.size.width, maxWidth: GeometryProxy.size.width)
                                    } else {
                                        // Show streaming text even when not completed
                                        if !jsonResponse.isEmpty && jsonResponse != "Pending..." {
                                            Text(jsonResponse)
                                                .focusEffectDisabled(false)
                                                .dynamicTypeSize(DynamicTypeSize.xSmall)
                                                .font(.body)
                                                .padding()
                                                .frame(idealWidth: GeometryProxy.size.width, maxWidth: GeometryProxy.size.width)
                                        } else {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .frame(idealWidth: GeometryProxy.size.width, maxWidth: GeometryProxy.size.width)
                                        }
                                    }
                                }
                                .padding()
                                .frame(idealWidth: GeometryProxy.size.width, maxWidth: GeometryProxy.size.width)
                                .glassEffect(in: .rect(cornerRadius: 25.0))
                            }
                        }
                        
//                        Spacer()
                    }
                }
            })
            .onAppear {
                psalmNumberInput = "\(psalmNumber)"
                Task {
                    await refreshQueue()
                }
            }
            .padding(.bottom, 75.0)
            
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, content: {
                    
                    Text("James Alan Bush")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Commit ID 7fe5119")
                        .font(.caption2)
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
                    Color.primary.opacity(0.25),
                    Color.accentColor.opacity(0.25)
                ]),
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
            .ignoresSafeArea()
            
            
        }
//        .focusable(true)
//        .textSelection(.enabled)
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func extractPlainText(from jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8) else { return "" }

        // Try to decode as dictionary with optional "name" and "paragraphs"
        struct Paragraph: Decodable {
            let content: String
        }

        struct Root: Decodable {
            let name: String?
            let paragraphs: [Paragraph]?
        }

        do {
            let decoded = try JSONDecoder().decode(Root.self, from: data)

            var result = ""
            if let name = decoded.name {
                result += name + "\n\n"
            }

            if let paragraphs = decoded.paragraphs {
                for paragraph in paragraphs {
                    result += paragraph.content + "\n\n"
                }
            }

            return result.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {
            return "Invalid JSON format"
        }
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
    
//    func selectableText(_ string: String) -> some View {
//        Text(string)
//            .textSelection(.enabled)
//            .focusable(true)
//            .focusEffectDisabled(false)
//    }
    
//    func extractTextFromJSON(_ jsonString: String) -> String {
//        struct Abstract: Decodable {
//            let name: String?
//            let paragraphs: [String]?
//        }
//
//        guard let data = jsonString.data(using: .utf8) else { return "" }
//
//        do {
//            let abstract = try JSONDecoder().decode(Abstract.self, from: data)
//            var result = ""
//
//            if let name = abstract.name {
//                result += name + "\n\n"
//            }
//
//            if let paragraphs = abstract.paragraphs {
//                result += paragraphs.joined(separator: "\n\n")
//            }
//
//            return result.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        } catch {
//            return "Invalid JSON format: \(error.localizedDescription)"
//        }
//    }
    
    func extractAllText(from jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8) else { return "" }

        func extractStrings(from value: Any) -> [String] {
            if let string = value as? String {
                return [string]
            } else if let array = value as? [Any] {
                return array.flatMap { extractStrings(from: $0) }
            } else if let dict = value as? [String: Any] {
                return dict.values.flatMap { extractStrings(from: $0) }
            } else {
                return []
            }
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let strings = extractStrings(from: json)
            return strings.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "Invalid JSON format: \(error.localizedDescription)"
        }
    }
    
    func extractTextRemovingJSONTags(_ jsonString: String) -> String {
        struct ContentWrapper: Decodable {
            let name: String?
            let paragraphs: [ParagraphType]?
        }

        enum ParagraphType: Decodable {
            case string(String)
            case object(ParagraphObject)

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let str = try? container.decode(String.self) {
                    self = .string(str)
                } else {
                    self = .object(try container.decode(ParagraphObject.self))
                }
            }

            var text: String {
                switch self {
                case .string(let s): return s
                case .object(let o): return o.content
                }
            }
        }

        struct ParagraphObject: Decodable {
            let content: String
        }

        guard let data = jsonString.data(using: .utf8) else {
            return "Invalid input encoding"
        }

        do {
            let decoded = try JSONDecoder().decode(ContentWrapper.self, from: data)
            var output = ""

            if let name = decoded.name {
                output += name + "\n\n"
            }

            if let paragraphs = decoded.paragraphs {
                output += paragraphs.map { $0.text }.joined(separator: "\n\n")
            }

            return output.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {
            return "Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    func extractTextFromJSON(_ input: String) -> String {
        var result = ""
        var insideQuotes = false
        var currentText = ""
        var isValue = false
        var previousChar: Character = " "
        
        for char in input {
            switch char {
            case "\"":
                if previousChar != "\\" {
                    if insideQuotes {
                        // End of quoted text
                        if isValue && !currentText.isEmpty {
                            result += currentText + "\n\n"
                        }
                        currentText = ""
                        isValue = false
                    }
                    insideQuotes = !insideQuotes
                }
                
            case ":":
                if !insideQuotes {
                    // Next quoted text will be a value
                    isValue = true
                } else {
                    currentText += String(char)
                }
                
            case "{", "}", "[", "]", ",":
                if insideQuotes {
                    currentText += String(char)
                }
                
            default:
                if insideQuotes {
                    currentText += String(char)
                }
            }
            
            previousChar = char
        }
        
        // Clean up extra newlines and trim
        result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Alternative simpler approach using regex
    func extractTextFromJSONSimple(_ input: String) -> String {
        // Match all text between quotes that comes after a colon
        let pattern = ":\\s*\"([^\"]*)\""
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
            
            var extractedTexts: [String] = []
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: input) {
                    let text = String(input[range])
                    if !text.isEmpty {
                        extractedTexts.append(text)
                    }
                }
            }
            
            return extractedTexts.joined(separator: "\n\n")
        } catch {
            return "Error processing text: \(error.localizedDescription)"
        }
    }

    // Alternative version using Codable for more type safety
    struct TextContent: Codable {
        let name: String?
        let paragraphs: [String]?
    }

    func extractTextFromJSONUsingCodable(_ jsonString: String) -> String {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return "Error: Unable to convert string to data"
        }
        
        do {
            let decoder = JSONDecoder()
            let content = try decoder.decode(TextContent.self, from: jsonData)
            
            var extractedText = ""
            
            // Add name if present
            if let name = content.name {
                extractedText += name + "\n\n"
            }
            
            // Add paragraphs if present
            if let paragraphs = content.paragraphs {
                extractedText += paragraphs.joined(separator: "\n\n")
            }
            
            return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "Error decoding JSON: \(error.localizedDescription)"
        }
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
    
    // MARK: - Add & Execute
    private func addPsalmAndRun() {
        Task {
            let abstract = await queue.addPsalm(psalmNumber)
            await refreshQueue()
            
            // Run the psalm abstract generation concurrently
            await runPsalmAbstract(abstract)
        }
    }
    
//    func removeJSONTags(_ input: String) -> String {
//        var result = ""
//        var insideQuotes = false
//        var currentText = ""
//        var skipThisQuotedText = false
//        var previousNonWhitespaceChar: Character = " "
//        
//        for char in input {
//            switch char {
//            case "\"":
//                if insideQuotes {
//                    // Ending quotes
//                    if !skipThisQuotedText {
//                        result += currentText
//                    }
//                    currentText = ""
//                    skipThisQuotedText = false
//                    insideQuotes = false
//                } else {
//                    // Starting quotes - check if preceded by brace
//                    insideQuotes = true
//                    if previousNonWhitespaceChar == "{" {
//                        skipThisQuotedText = true
//                    }
//                }
//                
//            default:
//                if insideQuotes {
//                    currentText += String(char)
//                } else {
//                    result += String(char)
//                }
//            }
//            
//            // Track previous non-whitespace character
//            if !char.isWhitespace {
//                previousNonWhitespaceChar = char
//            }
//        }
//        
//        // Clean up the result
//        // Remove empty braces, brackets, colons, and commas
//        result = result.replacingOccurrences(of: "[{}\\[\\]:,]", with: "", options: .regularExpression)
//        
//        // Clean up multiple spaces and newlines
//        result = result.replacingOccurrences(of: "[ ]+", with: " ", options: .regularExpression)
//        result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
//        
//        // Trim each line
//        let lines = result.components(separatedBy: .newlines)
//            .map { $0.trimmingCharacters(in: .whitespaces) }
//            .filter { !$0.isEmpty }
//        
//        return lines.joined(separator: "\n\n")
//    }

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
            
            guard let psalm = psalmText(from: allText, number: abstract.psalmNumber) else {
                await queue.updateResponse(for: abstract.id, response: "Error: Could not find Psalm \(abstract.psalmNumber) in the text file", isCompleted: true)
                await refreshQueue()
                return
            }
            
            // Create instructions with explicit plain text request
            let instructions = Instructions("""
                Your instructions:
                When prompted with a specific psalm (e.g., "Psalm 23" or "23"), you will write a six-paragraph abstract of psalm \(abstract.psalmNumber) by following the description for each paragraph.
                
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
                
                SAMPLE FORMAT FOR PSALM 23:
                "The LORD is my shepherd; I shall not want. He maketh me to lie down in green pastures: He leadeth me beside the still waters. He restoreth my soul: He leadeth me in the paths of righteousness for his name's sake. Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; Thy rod and thy staff they comfort me. Thou preparest a table before me in the presence of mine enemies: Thou anointest my head with oil; my cup runneth over. Surely goodness and mercy shall follow me all the days of my life: And I will dwell in the house of the LORD for ever."
                
                [Then follow with six paragraphs of plain text analysis]
                
                Cite the full text of Psalm \(abstract.psalmNumber) before beginning your abstract:
                \(psalm)
                """)
            
            let prompt = Prompt("Write an abstract for Psalm \(abstract.psalmNumber) per your instructions above.")
            let session = LanguageModelSession(instructions: instructions)
            
            // Stream response with throttled updates for better UI performance
            let stream = session.streamResponse(to: prompt, generating: String.PartiallyGenerated.self)
            var fullResponse = ""
            var lastUpdateTime = Date()

            for try await partial in stream {
                fullResponse = partial
                
                // Throttle UI updates to every 100ms for better performance
                let now = Date()
                if now.timeIntervalSince(lastUpdateTime) > 0.1 {
                    await queue.updateResponse(for: abstract.id, response: fullResponse, isCompleted: false)
                    await refreshQueue()
                    lastUpdateTime = now
                }
                
                // Optional: Reduced console printing for debugging
                // Uncomment the line below if you want to see streaming progress in console
                // print("Streaming: \(fullResponse.suffix(50))...") // Only show last 50 characters
            }
            
            // Final update with completion status
            if fullResponse.isEmpty {
                await queue.updateResponse(for: abstract.id, response: "Error: Received empty response from language model", isCompleted: true)
            } else {
                // Make sure we have the final complete response
                await queue.updateResponse(for: abstract.id, response: fullResponse, isCompleted: true)
                print("✅ Psalm \(abstract.psalmNumber) abstract completed successfully")
            }
            
        } catch {
            // Handle any streaming or session errors
            await queue.updateResponse(for: abstract.id, response: "Error: \(error.localizedDescription)", isCompleted: true)
            print("❌ Error generating Psalm \(abstract.psalmNumber): \(error.localizedDescription)")
        }
        
        // Always refresh queue at the end
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
