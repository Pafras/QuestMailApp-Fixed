//
//  ComposeActivityCard.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 21/04/26.
//

import SwiftUI

struct ComposeActivityCard: View {
    
    // MARK: - Theme
    private let accentTeal = Color(red: 0.24, green: 0.46, blue: 0.38)
    private let lightTeal = Color(red: 0.24, green: 0.46, blue: 0.38).opacity(0.08)
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    var onSubmitDismiss: (() -> Void)?
    
    @State private var questTitle: String = ""
    @State private var activity: String = ""
    @State private var reward: String = ""
    @State private var hostedBy: String = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var hasParticipantLimit = false
    @State private var participantCount: Int = 2
    @State private var showSuccess = false
    @State private var showTimePicker = false
    @State private var datePickerId = UUID()
    
    // MARK: - Computed
    private var isFormComplete: Bool {
        !questTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !activity.trimmingCharacters(in: .whitespaces).isEmpty &&
        !reward.trimmingCharacters(in: .whitespaces).isEmpty &&
        !hostedBy.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: Title
                        Text("Activity Card")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(accentTeal)
                            .padding(.top, 8)
                        
                        // MARK: Date Row
                        dateRow
                        
                        // MARK: Time Row
                        timeRow
                        
                        // MARK: Title Field
                        sectionField(
                            header: "TITLE",
                            placeholder: "Name your quest",
                            text: $questTitle,
                            isMultiline: false
                        )
                        
                        // MARK: Activity Field
                        sectionField(
                            header: "ACTIVITY",
                            placeholder: "What will you be doing ?",
                            text: $activity,
                            isMultiline: true
                        )
                        
                        // MARK: Reward Field
                        sectionField(
                            header: "WHAT YOU\u{2019}LL WALK AWAY WITH",
                            placeholder: "The reward for joining",
                            text: $reward,
                            isMultiline: true
                        )
                        
                        // MARK: Participants
                        participantRow
                        
                        // MARK: Who Field
                        sectionField(
                            header: "Who",
                            placeholder: "Hosted by...",
                            text: $hostedBy,
                            isMultiline: false
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                
                // MARK: Submit Button
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showSuccess = true
                    }
                } label: {
                    Text("Submit Quest")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isFormComplete
                                      ? accentTeal
                                      : Color(.systemGray4))
                        )
                }
                .disabled(!isFormComplete)
                .animation(.easeInOut(duration: 0.2), value: isFormComplete)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            
            // MARK: Success Overlay
            if showSuccess {
                successOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
    
    // MARK: - Date Row
    private var dateRow: some View {
        HStack {
            Label("Date", systemImage: "calendar")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(accentTeal)
            
            Spacer()
            
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
                .id(datePickerId)
                .onChange(of: selectedDate) { _, _ in
                    datePickerId = UUID()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(lightTeal)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(accentTeal.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Time Row
    private var timeRow: some View {
        Button {
            showTimePicker = true
        } label: {
            HStack {
                Label("Time", systemImage: "clock")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(accentTeal)
                
                Spacer()
                
                Text(selectedTime, format: .dateTime.hour().minute())
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accentTeal.opacity(0.1))
                    )
                    .foregroundStyle(accentTeal)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(lightTeal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(accentTeal.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(selectedTime: $selectedTime, accentTeal: accentTeal)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Participant Row
    private var participantRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PARTICIPANTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accentTeal.opacity(0.7))
                .textCase(.uppercase)
            
            // Open / Limited segmented control
            HStack(spacing: 0) {
                participantOption(
                    title: "Open",
                    subtitle: "Anyone can join",
                    icon: "person.3.fill",
                    isSelected: !hasParticipantLimit
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        hasParticipantLimit = false
                        participantCount = 2
                    }
                }
                
                participantOption(
                    title: "Limited",
                    subtitle: "Set max spots",
                    icon: "person.2.circle",
                    isSelected: hasParticipantLimit
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        hasParticipantLimit = true
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
            )
            
            // Counter (only visible when limit is on)
            if hasParticipantLimit {
                HStack {
                    Text("Max participants")
                        .font(.body)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            if participantCount > 2 {
                                participantCount -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(participantCount > 2 ? accentTeal : Color(.systemGray4))
                        }
                        .disabled(participantCount <= 2)
                        
                        Text("\(participantCount)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(minWidth: 30)
                            .contentTransition(.numericText())
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                participantCount += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(accentTeal)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
    }
    
    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSuccess = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onSubmitDismiss?()
                        dismiss()
                    }
                }
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(accentTeal)
                    .symbolEffect(.bounce, value: showSuccess)
                
                Text("Quest Submitted!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(accentTeal)
                
                Text("Your activity card has been\nsuccessfully added.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSuccess = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onSubmitDismiss?()
                        dismiss()
                    }
                } label: {
                    Text("Done")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentTeal)
                        )
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            )
            .padding(.horizontal, 40)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }
    
    // MARK: - Participant Option Button
    private func participantOption(title: String, subtitle: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? accentTeal.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? lightTeal : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? accentTeal.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .foregroundStyle(isSelected ? accentTeal : .secondary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Section Field
    private func sectionField(header: String, placeholder: String, text: Binding<String>, isMultiline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accentTeal.opacity(0.7))
                .textCase(.uppercase)
            
            if isMultiline {
                ZStack(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                    }
                    TextEditor(text: text)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(minHeight: 80)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
            } else {
                TextField(placeholder, text: text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }
}

// MARK: - TimePickerSheet (15-min interval)
struct TimePickerSheet: View {
    @Binding var selectedTime: Date
    let accentTeal: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Select Time")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(accentTeal)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // UIKit DatePicker with 15-min interval
            TimePicker15Min(selection: $selectedTime)
                .frame(height: 200)
            
            Spacer()
        }
    }
}

// MARK: - UIKit Wrapper for 15-min interval
struct TimePicker15Min: UIViewRepresentable {
    @Binding var selection: Date
    
    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = 15
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return picker
    }
    
    func updateUIView(_ picker: UIDatePicker, context: Context) {
        picker.date = selection
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }
    
    class Coordinator: NSObject {
        let selection: Binding<Date>
        init(selection: Binding<Date>) { self.selection = selection }
        
        @objc func dateChanged(_ picker: UIDatePicker) {
            selection.wrappedValue = picker.date
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ComposeActivityCard()
    }
}
