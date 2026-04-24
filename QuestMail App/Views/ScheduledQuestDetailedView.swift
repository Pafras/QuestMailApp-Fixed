//
//  ScheduledQuestDetailView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 23/04/26.
//

import SwiftUI

struct ScheduledQuestDetailView: View {

    // onRSVPChange: passed FROM MainAppView
    var onRSVPChange: (UUID, Bool) -> Void

    // questData: frozen snapshot from MainAppView's navigationDestination
    let questData: ScheduledQuest

    // rsvpedQuestIDs: shared binding back to MainAppView, keeps OnScheduleView in sync
    @Binding var rsvpedQuestIDs: Set<UUID>

    @Environment(\.dismiss) private var dismiss

    // MARK: - Local State
    @State private var showCancelConfirmation = false

    // local mirror of rsvpCount — seeds from questData on appear
    // needed because questData is a frozen copy and can't update itself
    @State private var localRsvpCount: Int = 0

    // MARK: - Computed
    private var isRSVPed: Bool {
        rsvpedQuestIDs.contains(questData.id)
    }

    private var isQuestFull: Bool {
        questData.participantType == .limited &&
        localRsvpCount >= (questData.maxParticipants ?? 0)
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: Title + Activity
                // source: questData.title, questData.activityDetail
                VStack(alignment: .leading, spacing: 10) {
                    Text(questData.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Divider()

                    Text("ACTIVITY")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    // LATER: filled from ComposeActivityCard's `activity` field
                    Text(questData.activityDetail)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                )

                // MARK: Reward
                // source: questData.reward
                // LATER: filled from ComposeActivityCard's `reward` field
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT YOU'LL WALK AWAY WITH")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(questData.reward)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                )

                // MARK: Logistics (Time, Place, Host)
                // source: questData.time, questData.venue, questData.organizer
                VStack(spacing: 0) {
                    missingDetailRow(icon: "clock.fill",         color: .blue,   label: "Time",  value: questData.time)
                    Divider().padding(.leading, 48)
                    missingDetailRow(icon: "mappin.circle.fill",  color: .red,    label: "Place", value: questData.venue)
                    Divider().padding(.leading, 48)
                    // LATER: filled from ComposeActivityCard's `hostedBy` field
                    missingDetailRow(icon: "person.circle.fill",  color: .purple, label: "Host",  value: questData.organizer)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                )

                // MARK: Participants
                // localRsvpCount used instead of questData.rsvpCount so it updates on RSVP
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Participants")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        // source: questData.participantType
                        Text(questData.participantType.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(questData.participantType == .open ? .green : .orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill((questData.participantType == .open ? Color.green : Color.orange).opacity(0.15))
                            )
                    }

                    if questData.participantType == .limited, let maxSlots = questData.maxParticipants {
                        // uses localRsvpCount so it reacts to RSVP immediately
                        Text("\(localRsvpCount) of \(maxSlots) spots taken")
                            .font(.caption)
                            .foregroundStyle(isQuestFull ? .red : .secondary)

                        if isQuestFull {
                            Text("FULL")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                        } else {
                            Text("\(maxSlots - localRsvpCount) spots left")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("\(localRsvpCount) joined")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                )

                // MARK: You're Going Badge
                // only shown when isRSVPed — same pattern as DesiresView's voted label
                if isRSVPed {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("You're going!")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                            Text("Your spot is reserved for this quest.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.green.opacity(0.25), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom) { rsvpButton }
        .overlay {
            if showCancelConfirmation { cancelOverlay }
        }
        .navigationBarTitleDisplayMode(.inline)
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
        // seeds localRsvpCount from the frozen questData snapshot
        .onAppear {
            localRsvpCount = questData.rsvpCount
        }
    }

    // MARK: - RSVP Button
    // PASSES TO: rsvpedQuestIDs binding → MainAppView → OnScheduleView checkmark
    // PASSES TO: onRSVPChange closure → MainAppView updates the array's rsvpCount
    // UPDATES: localRsvpCount so participant count reflects change immediately
    private var rsvpButton: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 8) {
                Button {
                    if isRSVPed {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showCancelConfirmation = true
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            rsvpedQuestIDs.insert(questData.id)  // syncs checkmark in OnScheduleView
                            onRSVPChange(questData.id, true)     // tells MainAppView to increment count
                            localRsvpCount += 1                  // updates participant count immediately
                        }
                    }
                } label: {
                    Text(
                        isRSVPed    ? "Cancel RSVP" :
                        isQuestFull ? "Quest is Full" :
                                      "RSVP — I'm in!"
                    )
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                isRSVPed    ? Color.red :
                                isQuestFull ? Color(.systemGray4) :
                                              Color.blue
                            )
                    )
                }
                .disabled(isQuestFull && !isRSVPed)

                if !isRSVPed && !isQuestFull {
                    Text("Or swipe the row in the list to RSVP instantly.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    // MARK: - Cancel Confirmation Overlay
    // same pattern as OnScheduleView's cancelConfirmationOverlay
    private var cancelOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showCancelConfirmation = false
                    }
                }

            VStack(spacing: 16) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)

                Text("Cancel RSVP?")
                    .font(.title3)
                    .fontWeight(.bold)

                // uses questData.title so user knows exactly which quest they're cancelling
                Text("Are you sure you want to cancel your RSVP for \"\(questData.title)\"?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showCancelConfirmation = false
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
                            rsvpedQuestIDs.remove(questData.id)  // syncs checkmark in OnScheduleView
                            onRSVPChange(questData.id, false)    // tells MainAppView to decrement count
                            localRsvpCount -= 1                  // updates participant count immediately
                            showCancelConfirmation = false
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
        }
    }

    // MARK: - missingDetailRow
    // reusable row for logisticsCard
    // `label` = what the slot shows, `value` = string from questData
    private func missingDetailRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview
// index [1] = Futsal — Limited quest, good for testing participant count update
#Preview {
    NavigationStack {
        ScheduledQuestDetailView(
            onRSVPChange: { _, _ in },
            questData: SampleData.scheduledQuests[1],
            rsvpedQuestIDs: .constant([])
        )
    }
}
