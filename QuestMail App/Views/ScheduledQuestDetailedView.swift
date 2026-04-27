//
//  ScheduledQuestDetailView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 23/04/26.
//
//  File ini berisi halaman detail untuk satu quest terjadwal.
//  Dibuka saat user tap quest di OnScheduleView.
//  Menampilkan semua informasi quest dan tombol RSVP/Cancel.
//
//  Struktur file:
//  1. ScheduledQuestDetailView — View utama halaman detail quest
//
//  Konsep penting - "Frozen Snapshot":
//  questData yang diterima dari navigationDestination adalah SALINAN (copy).
//  Artinya questData tidak akan berubah meskipun data asli di MainAppView berubah.
//  Karena itu, kita pakai localRsvpCount sebagai "mirror" yang bisa di-update lokal.
//

import SwiftUI

// MARK: - ScheduledQuestDetailView (Halaman Detail Quest)
/// Menampilkan detail lengkap satu quest: judul, aktivitas, reward,
/// lokasi, waktu, host, peserta, dan tombol RSVP.
struct ScheduledQuestDetailView: View {

    // MARK: - Properties dari Parent View

    /// Closure callback: dipanggil saat RSVP/cancel untuk mengupdate rsvpCount di MainAppView.
    /// Parameter: (questID, isJoining) — true = RSVP, false = cancel.
    var onRSVPChange: (UUID, Bool) -> Void

    /// Data quest yang ditampilkan — FROZEN SNAPSHOT (salinan, tidak berubah otomatis).
    /// Data ini disalin saat navigationDestination terbuka.
    let questData: ScheduledQuest

<<<<<<< Updated upstream
    // rsvpedQuestIDs: shared binding back to MainAppView — keeps OnScheduleView in sync
=======
    /// Set ID quest yang sudah di-RSVP — @Binding ke MainAppView.
    /// Perubahan di sini langsung terlihat di OnScheduleView (checkmark).
>>>>>>> Stashed changes
    @Binding var rsvpedQuestIDs: Set<UUID>

    /// Environment untuk menutup halaman ini (kembali ke list)
    @Environment(\.dismiss) private var dismiss

    // MARK: - State Lokal

    /// Mengontrol tampilan overlay konfirmasi cancel RSVP
    @State private var showCancelConfirmation = false

    /// Salinan lokal rsvpCount — dibutuhkan karena questData adalah frozen snapshot.
    /// Diisi dari questData.rsvpCount saat view muncul (onAppear).
    /// Diupdate langsung saat user RSVP/cancel supaya UI langsung berubah.
    @State private var localRsvpCount: Int = 0

    // MARK: - Computed Properties

    /// Cek apakah user sudah RSVP quest ini
    private var isRSVPed: Bool {
        rsvpedQuestIDs.contains(questData.id)
    }

    /// Cek apakah quest sudah penuh (hanya untuk tipe Limited)
    private var isQuestFull: Bool {
        questData.participantType == .limited &&
        localRsvpCount >= (questData.maxParticipants ?? 0)
    }

    // MARK: - Body (Layout Utama)
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: Card 1 — Title + Activity Detail
                VStack(alignment: .leading, spacing: 10) {
                    Text(questData.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Divider()

                    Text("ACTIVITY")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

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

                // MARK: Card 2 — Reward (Apa yang Didapat Peserta)
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

                // MARK: Card 3 — Logistics (Waktu, Tempat, Host)
                VStack(spacing: 0) {
                    missingDetailRow(icon: "clock.fill",         color: .blue,   label: "Time",  value: questData.formattedTime)
                    Divider().padding(.leading, 48)
                    missingDetailRow(icon: "mappin.circle.fill",  color: .red,    label: "Place", value: questData.venue)
                    Divider().padding(.leading, 48)
                    missingDetailRow(icon: "person.circle.fill",  color: .purple, label: "Host",  value: questData.organizer)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                )

                // MARK: Card 4 — Participants (Info Peserta)
                // Menggunakan localRsvpCount (bukan questData.rsvpCount)
                // supaya angka langsung berubah saat RSVP/cancel.
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Participants")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        // Badge "Open" atau "Limited" dengan warna berbeda
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
                        // Tipe Limited: tampilkan "X of Y spots taken"
                        Text("\(localRsvpCount) of \(maxSlots) spots taken")
                            .font(.caption)
                            .foregroundStyle(isQuestFull ? .red : .secondary)

                        if isQuestFull {
                            // Quest sudah penuh — tampilkan "FULL" merah
                            Text("FULL")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                        } else {
                            // Masih ada slot — tampilkan sisa slot
                            Text("\(maxSlots - localRsvpCount) spots left")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        // Tipe Open: tampilkan "X joined"
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

                // MARK: "You're Going!" Badge (Konfirmasi RSVP)
                // Hanya tampil jika user sudah RSVP — memberikan kepastian visual
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
        // MARK: Bottom RSVP Button (Fixed di Bawah Layar)
        // safeAreaInset: menambahkan konten di area bawah tanpa menutupi scroll content
        .safeAreaInset(edge: .bottom) { rsvpButton }
        // Overlay konfirmasi cancel
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
        // Inisialisasi localRsvpCount dari data quest saat view pertama kali muncul
        .onAppear {
            localRsvpCount = questData.rsvpCount
        }
    }

    // MARK: - rsvpButton — Tombol RSVP / Cancel (Fixed di Bawah)
    /// Tombol utama di bagian bawah layar untuk RSVP atau cancel.
    /// Teks dan warna berubah sesuai status:
    /// - Belum RSVP + ada slot → "RSVP — I'm in!" (biru)
    /// - Sudah RSVP → "Cancel RSVP" (merah)
    /// - Quest penuh + belum RSVP → "Quest is Full" (abu-abu, disabled)
    ///
    /// Alur data saat RSVP:
    /// 1. rsvpedQuestIDs.insert → sinkronisasi checkmark di OnScheduleView
    /// 2. onRSVPChange → MainAppView mengupdate rsvpCount di array utama
    /// 3. localRsvpCount += 1 → angka peserta langsung berubah di halaman ini
    private var rsvpButton: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 8) {
                Button {
                    if isRSVPed {
                        // Sudah RSVP → tampilkan konfirmasi cancel
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showCancelConfirmation = true
                        }
                    } else {
                        // Belum RSVP → langsung RSVP
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            rsvpedQuestIDs.insert(questData.id)
                            onRSVPChange(questData.id, true)
                            localRsvpCount += 1
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
                // Disabled jika quest penuh DAN user belum RSVP
                .disabled(isQuestFull && !isRSVPed)

                // Hint teks — hanya tampil jika bisa RSVP
                if !isRSVPed && !isQuestFull {
                    Text("Or swipe the row in the list to RSVP instantly.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.regularMaterial)  // Background blur di belakang tombol
        }
    }

    // MARK: - cancelOverlay — Popup Konfirmasi Cancel RSVP
    /// Overlay yang muncul saat user tekan "Cancel RSVP".
    /// Pola yang sama dengan OnScheduleView: "Keep" atau "Cancel RSVP".
    /// Alur cancel: hapus dari set → beritahu MainAppView → kurangi localCount.
    private var cancelOverlay: some View {
        ZStack {
            // Background gelap — tap untuk menutup (batal cancel)
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

                Text("Are you sure you want to cancel your RSVP for \"\(questData.title)\"?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    // Tombol Keep — batal cancel
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

                    // Tombol Cancel RSVP — konfirmasi cancel
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            rsvpedQuestIDs.remove(questData.id)   // Hapus dari set RSVP
                            onRSVPChange(questData.id, false)      // Beritahu MainAppView
                            localRsvpCount -= 1                    // Update count lokal
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

    // MARK: - missingDetailRow() — Baris Detail Logistik (Reusable)
    /// Komponen helper yang menampilkan satu baris informasi logistik (icon + label + value).
    /// Digunakan 3 kali di card Logistics: Time, Place, dan Host.
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
// Menggunakan index [1] = Futsal (Limited, 10/14) — bagus untuk testing participant count
#Preview {
    NavigationStack {
        ScheduledQuestDetailView(
            onRSVPChange: { _, _ in },
            questData: SampleData.scheduledQuests[1],
            rsvpedQuestIDs: .constant([])
        )
    }
}
