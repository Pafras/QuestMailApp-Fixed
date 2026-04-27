//
//  OnScheduleView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//
//  File ini berisi halaman "On Schedule" — tempat user melihat semua quest
//  yang sudah terjadwal, dikelompokkan berdasarkan waktu (This Week, Next Week, dll).
//  User bisa swipe kiri untuk RSVP/cancel, atau tap untuk melihat detail.
//
//  Struktur file:
//  1. OnScheduleView    — View utama: daftar quest per section + cancel overlay
//  2. SwipeableQuestRow — Komponen baris quest dengan fitur swipe kiri
//  3. QuestRow          — Komponen visual satu baris quest (icon, info, tanggal)
//

import SwiftUI

// MARK: - OnScheduleView (View Utama Halaman On Schedule)
/// Menampilkan daftar quest yang sudah terjadwal, dikelompokkan per waktu.
/// User bisa swipe kiri untuk RSVP/cancel, tap untuk buka detail.
struct OnScheduleView: View {

    // MARK: - Properties dari Parent View

    /// Daftar semua quest terjadwal — read-only dari MainAppView
    let quests: [ScheduledQuest]

    /// Quest yang dipilih — di-bind ke MainAppView untuk navigasi ke detail
    @Binding var selectedQuest: ScheduledQuest?

    /// Set ID quest yang sudah di-RSVP — di-bind untuk sinkronisasi checkmark
    @Binding var rsvpedQuestIDs: Set<UUID>

    /// Closure callback: dipanggil saat RSVP atau cancel.
    /// Parameter: (questID, isJoining) — isJoining true = RSVP, false = cancel.
    /// Mengupdate rsvpCount di MainAppView.
    var onRSVPChange: (UUID, Bool) -> Void

    // MARK: - State Lokal

    /// Quest yang user ingin cancel RSVP-nya (untuk ditampilkan di overlay konfirmasi)
    @State private var questToCancel: ScheduledQuest?

    /// Mengontrol tampilan overlay konfirmasi cancel RSVP
    @State private var showCancelConfirmation = false

    // MARK: - Body
    var body: some View {
        questScrollContent
            .overlay {
                // Overlay konfirmasi cancel ditampilkan di atas konten
                if showCancelConfirmation {
                    cancelConfirmationOverlay
                }
            }
    }

    // MARK: - sortedSections — Mengelompokkan Quest ke Section
    /// Membuat daftar section (This Week, Next Week, May 2026, dll) dari tanggal quest.
    /// Menggunakan Set untuk menghilangkan duplikat section, lalu diurutkan berdasarkan waktu.
    private var sortedSections: [ScheduleSection] {
        let sections = Set(quests.map { ScheduleSection.from(date: $0.scheduledDate) })
        return sections.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - questScrollContent — Konten Scrollable
    private var questScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Swipe Hint (Petunjuk Swipe untuk User)
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

                // MARK: Quest Sections (Daftar Quest per Kelompok Waktu)
                // Loop setiap section dan tampilkan quest-quest di dalamnya
                ForEach(sortedSections, id: \.self) { section in
                    questSection(section)
                }
            }
        }
    }

    // MARK: - questSection() — Membuat Satu Section (Header + Daftar Quest)
    /// @ViewBuilder memungkinkan fungsi mengembalikan beberapa view secara kondisional.
    /// Memfilter quest yang masuk ke section ini, lalu menampilkan header + baris quest.
    @ViewBuilder
    private func questSection(_ section: ScheduleSection) -> some View {
        // Filter quest yang tanggalnya masuk ke section ini, urutkan dari yang terdekat
        let sectionQuests = quests
            .filter { ScheduleSection.from(date: $0.scheduledDate) == section }
            .sorted { $0.scheduledDate < $1.scheduledDate }

        if !sectionQuests.isEmpty {
            // Section header (contoh: "This Week", "Next Week", "May 2026")
            Text(section.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Daftar quest dalam section ini
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

    // MARK: - confirmRSVP() — Proses RSVP Langsung
    /// Dipanggil saat user swipe dan tekan RSVP.
    /// Menambahkan quest ID ke set dan memberitahu MainAppView.
    private func confirmRSVP(_ quest: ScheduledQuest) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rsvpedQuestIDs.insert(quest.id)     // Tambahkan ke set RSVP
            onRSVPChange(quest.id, true)         // Beritahu MainAppView untuk update rsvpCount
        }
    }

    // MARK: - requestCancel() — Minta Konfirmasi Cancel RSVP
    /// Dipanggil saat user swipe dan tekan Cancel.
    /// Tidak langsung cancel — menampilkan overlay konfirmasi terlebih dahulu.
    private func requestCancel(_ quest: ScheduledQuest) {
        questToCancel = quest
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showCancelConfirmation = true
        }
    }

    // MARK: - cancelConfirmationOverlay — Popup Konfirmasi Cancel RSVP
    /// Overlay yang muncul saat user ingin cancel RSVP.
    /// Menampilkan 2 tombol: "Keep" (batal cancel) dan "Cancel RSVP" (konfirmasi cancel).
    @ViewBuilder
    private var cancelConfirmationOverlay: some View {
        if let quest = questToCancel {
            ZStack {
                // Background gelap — tap untuk menutup (batal cancel)
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

                    // Menampilkan judul quest yang akan di-cancel
                    Text("Are you sure you want to cancel your RSVP for \"\(quest.title)\"?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        // Tombol Keep — batal cancel, tutup overlay
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

                        // Tombol Cancel RSVP — konfirmasi cancel
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                rsvpedQuestIDs.remove(quest.id)     // Hapus dari set RSVP
                                onRSVPChange(quest.id, false)        // Beritahu MainAppView
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

// MARK: - SwipeableQuestRow (Baris Quest dengan Fitur Swipe Kiri)
/// Wrapper di sekitar QuestRow yang menambahkan fitur swipe-to-reveal.
/// Saat user swipe ke kiri, muncul tombol aksi (RSVP atau Cancel).
/// Saat user tap (tanpa swipe), navigasi ke halaman detail quest.
///
/// Cara kerja swipe:
/// 1. QuestRow ditampilkan di atas action button (ZStack)
/// 2. Drag gesture menggeser QuestRow ke kiri → action button terlihat
/// 3. Jika geseran > 50% dari actionWidth → tetap terbuka (isRevealed = true)
/// 4. Jika kurang → snap kembali ke posisi semula
struct SwipeableQuestRow: View {

    // MARK: - Properties
    let quest: ScheduledQuest
    @Binding var selectedQuest: ScheduledQuest?
    let isRSVPed: Bool
    let onRSVP: () -> Void
    let onCancelRequest: () -> Void

    // MARK: - State Lokal (Kontrol Swipe)

    /// Posisi horizontal QuestRow (0 = normal, negatif = tergeser ke kiri)
    @State private var offset: CGFloat = 0

    /// Apakah action button sedang terlihat (row sudah tergeser)
    @State private var isRevealed = false

    /// Lebar area action button (RSVP/Cancel) yang muncul saat swipe
    private let actionWidth: CGFloat = 80

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .trailing) {
            // MARK: Action Button (Tersembunyi di Belakang Row)
            // Tombol ini berada di belakang QuestRow, terlihat saat row digeser
            actionButton

            // MARK: Row Content (Konten Quest di Atas)
            QuestRow(quest: quest, isRSVPed: isRSVPed)
                .background(Color(.systemBackground))
                .offset(x: offset)                    // Posisi mengikuti gesture
                .simultaneousGesture(dragGesture)     // Gesture swipe horizontal
                .onTapGesture {
                    if isRevealed {
                        // Jika action sudah terbuka, tap = tutup kembali
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = 0
                            isRevealed = false
                        }
                    } else {
                        // Jika normal, tap = navigasi ke detail
                        selectedQuest = quest
                    }
                }
        }
        .clipped()  // Potong konten yang keluar dari bounds (action button di kanan)
        // Reset posisi swipe saat status RSVP berubah
        .onChange(of: isRSVPed) { _, _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                offset = 0
                isRevealed = false
            }
        }
    }

    // MARK: - actionButton — Tombol Aksi (RSVP / Cancel)
    /// Tombol yang muncul di belakang row saat digeser ke kiri.
    /// Warna hijau + checkmark jika belum RSVP.
    /// Warna merah + xmark jika sudah RSVP.
    private var actionButton: some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                // Tutup swipe dulu, lalu eksekusi aksi
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    isRevealed = false
                }
                if isRSVPed {
                    onCancelRequest()   // Sudah RSVP → minta konfirmasi cancel
                } else {
                    onRSVP()            // Belum RSVP → langsung RSVP
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
                    // Lebar berubah sesuai posisi geser atau tetap saat terbuka
                    .frame(width: isRevealed ? actionWidth : max(-offset, 0))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Drag Gesture (Logika Swipe Horizontal)

    /// Melacak apakah gesture pertama horizontal atau vertikal
    @State private var isHorizontalDrag: Bool? = nil

    /// Gesture swipe yang menggeser QuestRow ke kiri/kanan.
    /// Langkah-langkah:
    /// 1. Deteksi arah gesture pertama (horizontal vs vertikal)
    /// 2. Jika horizontal: geser row mengikuti jari
    /// 3. Saat dilepas: snap ke posisi terbuka atau tertutup (threshold 50%)
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // Deteksi arah gesture pada gerakan pertama
                if isHorizontalDrag == nil {
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    isHorizontalDrag = horizontal > vertical
                }
                // Hanya proses swipe horizontal — biarkan ScrollView handle vertikal
                guard isHorizontalDrag == true else { return }

                if value.translation.width < 0 && !isRevealed {
                    // Geser ke kiri (buka action) — hanya jika belum terbuka
                    offset = value.translation.width
                } else if value.translation.width > 0 && isRevealed {
                    // Geser ke kanan (tutup action) — hanya jika sudah terbuka
                    offset = min(-actionWidth + value.translation.width, 0)
                }
            }
            .onEnded { _ in
                defer { isHorizontalDrag = nil }  // Reset deteksi arah
                guard isHorizontalDrag == true else { return }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if !isRevealed && -offset > actionWidth * 0.5 {
                        // Geseran > 50% → snap ke terbuka
                        offset = -actionWidth
                        isRevealed = true
                    } else if isRevealed && offset > -actionWidth * 0.5 {
                        // Geseran kembali > 50% → snap ke tertutup
                        offset = 0
                        isRevealed = false
                    } else if isRevealed {
                        // Masih di posisi terbuka
                        offset = -actionWidth
                    } else {
                        // Geseran kurang → snap kembali ke tertutup
                        offset = 0
                    }
                }
            }
    }
}

// MARK: - QuestRow (Komponen Visual Satu Baris Quest)
/// Komponen visual yang menampilkan informasi satu quest dalam satu baris.
/// Digunakan di: OnScheduleView (via SwipeableQuestRow) dan HistoryView.
/// Terdiri dari: icon, info (title, venue, participants), dan tanggal/waktu.
struct QuestRow: View {

    /// Data quest yang ditampilkan
    let quest: ScheduledQuest

    /// Apakah user sudah RSVP quest ini — menampilkan checkmark di icon
    var isRSVPed: Bool = false

    // MARK: - Body
    var body: some View {
        HStack(spacing: 14) {
            questIcon       // Icon quest (kiri)
            questInfo       // Info: title, venue, participants (tengah)
            Spacer()
            questDateTime   // Tanggal & waktu (kanan)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - questIcon — Icon Quest dengan Badge Checkmark
    /// Icon kotak dengan SF Symbol. Jika sudah RSVP, ada badge checkmark hijau di sudut.
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
            // Badge checkmark hijau — hanya muncul jika sudah RSVP
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

    // MARK: - questInfo — Informasi Quest (Title, Venue, Participants)
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

    // MARK: - participantLabel — Label Jumlah Peserta
    /// Menampilkan jumlah peserta dalam format berbeda sesuai tipe:
    /// - Open: "5 joined" (berapa yang sudah join)
    /// - Limited: "10/14" (berapa dari maksimal)
    /// Warna merah jika quest sudah penuh.
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

    /// Teks peserta: "5 joined" (Open) atau "10/14" (Limited)
    private var participantText: String {
        if quest.participantType == .open {
            return "\(quest.rsvpCount) joined"
        } else {
            return "\(quest.rsvpCount)/\(quest.maxParticipants ?? 0)"
        }
    }

    /// Warna teks peserta: merah jika sudah penuh, abu-abu jika belum
    private var participantColor: Color {
        if quest.participantType == .limited && quest.rsvpCount >= (quest.maxParticipants ?? 0) {
            return .red
        }
        return .secondary
    }

    // MARK: - questDateTime — Tanggal dan Waktu Quest
    /// Menampilkan tanggal (dd/MM) dan waktu (h:mm a) di sisi kanan baris.
    private var questDateTime: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(quest.formattedDate)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(quest.formattedTime)
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
