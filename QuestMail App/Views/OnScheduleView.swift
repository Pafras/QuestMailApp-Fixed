//
//  OnScheduleView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//

import SwiftUI

// MARK: - OnScheduleView
struct OnScheduleView: View {
    let quests: [ScheduledQuest]
    @Binding var selectedQuest: ScheduledQuest?
    @Binding var rsvpedQuestIDs: Set<UUID>
    
    // onRSVPChange: passed FROM MainAppView
    // questID = which quest, isJoining = true when RSVPing, false when cancelling
    var onRSVPChange: (UUID, Bool) -> Void

    // MARK: Cancel Confirmation State
    @State private var questToCancel: ScheduledQuest?
    @State private var showCancelConfirmation = false

    // MARK: - Body
    var body: some View {
        questScrollContent
            .overlay {
                if showCancelConfirmation {
                    cancelConfirmationOverlay
                }
            }
    }

    // MARK: - Scroll Content
    private var questScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: Swipe Hint
                HStack {
                    Image(systemName: "hand.draw")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("swipe left to RSVP or cancel")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                // MARK: Quest Sections
                ForEach(QuestSection.allCases, id: \.self) { section in
                    questSection(section)
                }
            }
        }
    }

    // MARK: - Section Builder
    @ViewBuilder
    private func questSection(_ section: QuestSection) -> some View {
        let sectionQuests = quests.filter { $0.section == section }
        if !sectionQuests.isEmpty {
            Text(section.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(sectionQuests) { quest in
                SwipeableQuestRow(
                    quest: quest,
                    selectedQuest: $selectedQuest,
                    isRSVPed: rsvpedQuestIDs.contains(quest.id),
                    onRSVP: { confirmRSVP(quest) },
                    onCancelRequest: { requestCancel(quest) }
                )
                Divider()
                    .padding(.horizontal)
            }
        }
    }

    private func confirmRSVP(_ quest: ScheduledQuest) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rsvpedQuestIDs.insert(quest.id)
            onRSVPChange(quest.id, true)
        }
    }

    private func requestCancel(_ quest: ScheduledQuest) {
        questToCancel = quest
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showCancelConfirmation = true
        }
    }

    // MARK: - Cancel Confirmation Overlay
    @ViewBuilder
    private var cancelConfirmationOverlay: some View {
        if let quest = questToCancel {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showCancelConfirmation = false
                            questToCancel = nil
                        }
                    }

                VStack(spacing: 16) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)

                    Text("Cancel RSVP?")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Are you sure you want to cancel your RSVP for \"\(quest.title)\"?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showCancelConfirmation = false
                                questToCancel = nil
                            }
                        } label: {
                            Text("Keep")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray5))
                                )
                        }

                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                rsvpedQuestIDs.remove(quest.id)
                                onRSVPChange(quest.id, false)
                                showCancelConfirmation = false
                                questToCancel = nil
                            }
                        } label: {
                            Text("Cancel RSVP")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red)
                                )
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                )
                .padding(.horizontal, 36)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
    }
}

// MARK: - SwipeableQuestRow (Swipe to reveal, tap to confirm)
struct SwipeableQuestRow: View {
    let quest: ScheduledQuest
    @Binding var selectedQuest: ScheduledQuest?
    let isRSVPed: Bool
    let onRSVP: () -> Void
    let onCancelRequest: () -> Void

    // MARK: Properties
    @State private var offset: CGFloat = 0
    @State private var isRevealed = false
    private let actionWidth: CGFloat = 80

    // MARK: Body
    var body: some View {
        ZStack(alignment: .trailing) {
            // MARK: Action Background Button
            actionButton

            // MARK: Row Content
            QuestRow(quest: quest, isRSVPed: isRSVPed)
                .background(Color(.systemBackground))
                .offset(x: offset)
                .gesture(dragGesture)
                .onTapGesture {
                    if isRevealed {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = 0
                            isRevealed = false
                        }
                    } else {
                        selectedQuest = quest
                    }
                }
        }
        .clipped()
        .onChange(of: isRSVPed) { _, _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                offset = 0
                isRevealed = false
            }
        }
    }

    // MARK: Action Button
    private var actionButton: some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    isRevealed = false
                }
                if isRSVPed {
                    onCancelRequest()
                } else {
                    onRSVP()
                }
            } label: {
                Rectangle()
                    .fill(isRSVPed ? Color.red : Color.green)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: isRSVPed ? "xmark" : "checkmark")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text(isRSVPed ? "Cancel" : "RSVP")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                    }
                    .frame(width: isRevealed ? actionWidth : max(-offset, 0))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.width < 0 && !isRevealed {
                    offset = value.translation.width
                } else if value.translation.width > 0 && isRevealed {
                    offset = min(-actionWidth + value.translation.width, 0)
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if !isRevealed && -offset > actionWidth * 0.5 {
                        offset = -actionWidth
                        isRevealed = true
                    } else if isRevealed && offset > -actionWidth * 0.5 {
                        offset = 0
                        isRevealed = false
                    } else if isRevealed {
                        offset = -actionWidth
                    } else {
                        offset = 0
                    }
                }
            }
    }
}

// MARK: - QuestRow (Single Quest Item)
struct QuestRow: View {
    let quest: ScheduledQuest
    var isRSVPed: Bool = false

    // MARK: Body
    var body: some View {
        HStack(spacing: 14) {
            questIcon
            questInfo
            Spacer()
            questDateTime
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: Icon
    private var questIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: 48, height: 48)

            Image(systemName: quest.iconName)
                .font(.title3)
                .foregroundStyle(.primary)
        }
        .overlay(alignment: .topTrailing) {
            if isRSVPed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .background(Circle().fill(.white).padding(-1))
                    .offset(x: 4, y: -4)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: Info
    private var questInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(quest.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(quest.venue)
                .font(.caption)
                .foregroundStyle(.secondary)
            participantLabel
        }
    }

    // MARK: Participant Label
    private var participantLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(participantText)
                .font(.caption2)
                .foregroundStyle(participantColor)
        }
    }

    private var participantText: String {
        if quest.participantType == .open {
            return "\(quest.rsvpCount) joined"
        } else {
            return "\(quest.rsvpCount)/\(quest.maxParticipants ?? 0)"
        }
    }

    private var participantColor: Color {
        if quest.participantType == .limited && quest.rsvpCount >= (quest.maxParticipants ?? 0) {
            return .red
        }
        return .secondary
    }

    // MARK: Date & Time
    private var questDateTime: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(quest.date)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(quest.time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    OnScheduleView(
        quests: SampleData.scheduledQuests,
        selectedQuest: .constant(nil),
        rsvpedQuestIDs: .constant([]),
        onRSVPChange: { _, _ in }
    )
}
