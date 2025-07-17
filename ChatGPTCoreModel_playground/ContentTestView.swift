import SwiftUI

struct ContentTestView: View {
    @State private var psalmValue: Int = 1
    @State private var psalmStringValue: String = "1"
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var minusTimer: Timer?
    @State private var plusTimer: Timer?
    @State private var minusStepCount: Int = 0
    @State private var plusStepCount: Int = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PSALM")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Custom Stepper Control
            HStack(spacing: 0) {
                // Minus button
                Button(action: {}) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
                .disabled(psalmValue <= 1)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if minusTimer == nil && psalmValue > 1 {
                                decrementValue()
                                startMinusTimer()
                            }
                        }
                        .onEnded { _ in
                            stopMinusTimer()
                        }
                )
                
                // Editable value display
                TextField("", text: $psalmStringValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .onChange(of: psalmStringValue) { newValue in
                        // Filter out non-numeric characters
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            psalmStringValue = filtered
                        }
                        
                        // Update the integer value only if not empty
                        if !filtered.isEmpty {
                            if let intValue = Int(filtered), intValue >= 1 && intValue <= 150 {
                                psalmValue = intValue
                            } else if let intValue = Int(filtered) {
                                // Clamp to valid range
                                if intValue < 1 {
                                    psalmValue = 1
                                    psalmStringValue = "1"
                                } else if intValue > 150 {
                                    psalmValue = 150
                                    psalmStringValue = "150"
                                }
                            }
                        }
                        // If filtered is empty, leave stringValue empty but don't update value
                    }
                    .onSubmit {
                        // Handle when user submits (e.g., hits return)
                        if psalmStringValue.isEmpty {
                            psalmValue = 1
                            psalmStringValue = "1"
                        }
                        isTextFieldFocused = false
                    }
                
                // Plus button
                Button(action: {}) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
                .disabled(psalmValue >= 150)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if plusTimer == nil && psalmValue < 150 {
                                incrementValue()
                                startPlusTimer()
                            }
                        }
                        .onEnded { _ in
                            stopPlusTimer()
                        }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
            
            // Display the current value without modifying it
            Text("Current Psalm: \(psalmStringValue)")
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.top, 10)
            
            // Dismiss keyboard button
            if isTextFieldFocused {
                Button("Done") {
                    // If field is empty when dismissing, set to 1
                    if psalmStringValue.isEmpty {
                        psalmValue = 1
                        psalmStringValue = "1"
                    }
                    isTextFieldFocused = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func incrementValue() {
        if psalmValue < 150 {
            psalmValue += 1
            psalmStringValue = "\(psalmValue)"
        }
    }
    
    private func decrementValue() {
        if psalmValue > 1 {
            psalmValue -= 1
            psalmStringValue = "\(psalmValue)"
        }
    }
    
    private func startPlusTimer() {
        plusStepCount = 1  // Start at 1 since we already did the first step
        plusTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            plusStepCount += 1
            
            // Calculate when to step based on progressive timing
            let shouldStep: Bool
            if plusStepCount <= 5 {
                shouldStep = (plusStepCount - 1) % 5 == 0  // Steps at count 1, 6 (every 0.5s initially)
            } else if plusStepCount <= 15 {
                shouldStep = (plusStepCount - 6) % 3 == 0  // Steps at count 6, 9, 12, 15 (every 0.3s)
            } else if plusStepCount <= 30 {
                shouldStep = (plusStepCount - 16) % 2 == 0  // Steps at count 16, 18, 20, etc. (every 0.2s)
            } else {
                shouldStep = true  // Every 0.1s at maximum speed
            }
            
            if shouldStep && psalmValue < 150 {
                incrementValue()
            } else if psalmValue >= 150 {
                stopPlusTimer()
            }
        }
    }
    
    private func startMinusTimer() {
        minusStepCount = 1  // Start at 1 since we already did the first step
        minusTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            minusStepCount += 1
            
            // Calculate when to step based on progressive timing
            let shouldStep: Bool
            if minusStepCount <= 5 {
                shouldStep = (minusStepCount - 1) % 5 == 0  // Steps at count 1, 6 (every 0.5s initially)
            } else if minusStepCount <= 15 {
                shouldStep = (minusStepCount - 6) % 3 == 0  // Steps at count 6, 9, 12, 15 (every 0.3s)
            } else if minusStepCount <= 30 {
                shouldStep = (minusStepCount - 16) % 2 == 0  // Steps at count 16, 18, 20, etc. (every 0.2s)
            } else {
                shouldStep = true  // Every 0.1s at maximum speed
            }
            
            if shouldStep && psalmValue > 1 {
                decrementValue()
            } else if psalmValue <= 1 {
                stopMinusTimer()
            }
        }
    }
    
    private func stopPlusTimer() {
        plusTimer?.invalidate()
        plusTimer = nil
        plusStepCount = 0
    }
    
    private func stopMinusTimer() {
        minusTimer?.invalidate()
        minusTimer = nil
        minusStepCount = 0
    }
}

#Preview {
    ContentTestView()
}
