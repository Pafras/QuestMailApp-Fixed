//
//  HistoryView.swift
//  QuestMail App
//
//  Created by Eduardo Richie Imanuell on 24/04/26.
//
//  File ini berisi halaman "History" — tempat user melihat quest yang sudah mereka
//  RSVP-kan, dibagi menjadi 2 section: Upcoming (belum terjadi) dan Completed (sudah lewat).
//
//  Struktur file:
//  1. HistoryView — View utama yang menampilkan daftar quest yang di-RSVP
//
//  Catatan penting:
//  - View ini READ-ONLY (hanya menampilkan, tidak mengubah data)
//  - Menggunakan QuestRow dari OnScheduleView (komponen yang dipakai ulang)
//  - Data berasal dari MainAppView: scheduledQuests array + rsvpedQuestIDs set
//

import SwiftUI

// MARK: - HistoryView (View Utama Halaman History)
/// Menampilkan quest yang sudah di-RSVP oleh user.
/// Quest dibagi menjadi 2 section:
/// - Upcoming: quest yang tanggalnya belum lewat (diurutkan dari yang terdekat)
/// - Completed: quest yang tanggalnya sudah lewat (diurutkan dari yang paling baru)
struct HistoryView: View {

    // MARK: - Properties dari Parent View (Read-Only)

    /// Semua data quest dari MainAppView — read-only (let, bukan @Binding)
    /// karena view ini hanya menampilkan, tidak perlu mengubah data quest.
    let questsData: [ScheduledQuest]

    /// Set berisi ID quest yang sudah di-RSVP oleh user.
    /// Juga read-only — HistoryView tidak perlu menambah/menghapus RSVP.
    /// Data ini digunakan untuk memfilter quest mana saja yang ditampilkan.
    let rsvpedQuestIDs: Set<UUID>

    // MARK: - Computed Properties (Filter dan Sorting)

    /// Filter: hanya quest yang ID-nya ada di rsvpedQuestIDs.
    /// Ini menghasilkan daftar quest yang user benar-benar ikuti.
    private var rsvpedQuests: [ScheduledQuest] {
        questsData.filter { questItem in rsvpedQuestIDs.contains(questItem.id) }
    }

    /// Quest yang belum terjadi — tanggal >= hari ini.
    /// Diurutkan: yang paling dekat tanggalnya muncul paling atas.
    private var upcomingQuests: [ScheduledQuest] {
        rsvpedQuests
            .filter { questItem in
                questItem.scheduledDate >= Date()
            }
            .sorted { firstQuest, secondQuest in
                firstQuest.scheduledDate < secondQuest.scheduledDate
            }
    }

    /// Quest yang sudah lewat — tanggal < hari ini.
    /// Diurutkan: yang paling baru lewat muncul paling atas.
    private var completedQuests: [ScheduledQuest] {
        rsvpedQuests
            .filter { questItem in
                questItem.scheduledDate < Date()
            }
            .sorted { firstQuest, secondQuest in
                firstQuest.scheduledDate > secondQuest.scheduledDate
            }
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Upcoming Section (Quest yang Akan Datang)
                Text("Upcoming")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                if upcomingQuests.isEmpty {
                    // Pesan kosong jika belum ada quest upcoming yang di-RSVP
                    emptyState(message: "No upcoming quests. Go RSVP to something!")
                } else {
                    ForEach(upcomingQuests) { questItem in
                        // Menggunakan QuestRow yang sama dengan OnScheduleView (reuse komponen)
                        // isRSVPed selalu true karena sudah difilter hanya quest yang di-RSVP
                        QuestRow(quest: questItem, isRSVPed: true)
                        Divider().padding(.horizontal)
                    }
                }

                // MARK: Completed Section (Quest yang Sudah Lewat)
                Text("Completed")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                if completedQuests.isEmpty {
                    // Pesan kosong jika belum ada quest completed
                    emptyState(message: "No completed quests yet.")
                } else {
                    ForEach(completedQuests) { questItem in
                        // Quest yang sudah lewat ditampilkan dengan opacity 0.5 (samar)
                        // sebagai petunjuk visual bahwa quest ini sudah selesai
                        QuestRow(quest: questItem, isRSVPed: true)
                            .opacity(0.5)
                        Divider().padding(.horizontal)
                    }
                }

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - emptyState() — Pesan Kosong (Reusable)
    /// Komponen helper yang menampilkan pesan saat list kosong.
    /// Digunakan di section Upcoming dan Completed.
    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }
}

// MARK: - Preview
#Preview {
    HistoryView(
        questsData: SampleData.scheduledQuests,
        // Simulasi: user sudah RSVP ke quest index [0] dan [1]
        rsvpedQuestIDs: [
            SampleData.scheduledQuests[0].id,
            SampleData.scheduledQuests[1].id
        ]
    )
}
