//
//  DesiresView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//
//  File ini berisi halaman "Desires" — tempat user melihat daftar aktivitas
//  yang diinginkan, melakukan vote, dan menambahkan desire baru.
//
//  Struktur file:
//  1. DesiresView        — View utama yang menampilkan semua desire cards
//  2. FeaturedDesireCard — Card besar untuk 2 desire teratas (vote tertinggi)
//  3. DesireCard         — Card kecil grid untuk desire lainnya
//  4. AddDesireSheet     — Bottom sheet form untuk menambah desire baru
//

import SwiftUI

// MARK: - DesiresView (View Utama Halaman Desires)
/// View utama yang menampilkan daftar desire activities.
/// Desire diurutkan berdasarkan jumlah vote — 2 teratas jadi "Featured",
/// sisanya ditampilkan dalam grid 2 kolom di bagian "Others".
struct DesiresView: View {

    // MARK: - Properties dari Parent View
    // @Binding artinya data ini dimiliki oleh parent view (MainAppView),
    // perubahan di sini akan otomatis mengupdate parent dan sebaliknya.

    /// Daftar semua desire activities — di-bind dari parent supaya perubahan sinkron
    @Binding var activities: [DesireActivity]

    /// Desire yang sedang dipilih user (untuk navigasi ke detail) — nil kalau belum ada yang dipilih
    @Binding var selectedActivity: DesireActivity?

    /// Closure callback: dipanggil saat user tekan tombol compose (pencil icon) di featured card.
    /// Mengirim UUID desire yang ingin di-compose ke parent view.
    var onComposeQuest: (UUID) -> Void

    // MARK: - State Properties (Data Lokal View Ini)
    // @State artinya data ini dimiliki dan dikelola oleh view ini sendiri.
    // Kalau nilainya berubah, SwiftUI otomatis re-render UI.

    /// Menyimpan ID desire yang sudah di-vote oleh user (Set supaya tidak duplikat)
    @State private var votedIDs: Set<UUID> = []

    /// Mengontrol apakah sheet "Add Desire" sedang tampil atau tidak
    @State private var showAddDesire = false

    /// Mengontrol apakah popup sukses "Desire Added!" sedang tampil
    @State private var showAddSuccess = false

    /// ID card yang sedang dalam animasi bounce saat di-vote (nil = tidak ada yang animasi)
    @State private var animatingVoteID: UUID?

    /// Namespace untuk matchedGeometryEffect — membuat animasi perpindahan card smooth
    /// saat urutan berubah karena vote
    @Namespace private var cardAnimation

    // MARK: - Computed Properties (Data yang Dihitung Otomatis)
    // Computed property tidak menyimpan data, tapi menghitung nilainya
    // setiap kali diakses berdasarkan data lain.

    /// Mengurutkan activities berdasarkan jumlah vote dari yang terbanyak
    private var sortedActivities: [DesireActivity] {
        activities.sorted { $0.wantCount > $1.wantCount }
    }

    /// Mengambil 2 desire teratas (vote terbanyak) untuk ditampilkan sebagai Featured
    private var featuredActivities: [DesireActivity] {
        Array(sortedActivities.prefix(2))
    }

    /// Mengambil sisa desire setelah 2 teratas untuk ditampilkan di bagian Others (grid)
    private var otherActivities: [DesireActivity] {
        Array(sortedActivities.dropFirst(2))
    }

    /// Konfigurasi grid 2 kolom dengan spacing 12pt untuk bagian Others
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Body (Layout Utama)
    var body: some View {
        // ZStack menumpuk layer: ScrollView content + floating button + success popup
        ZStack(alignment: .bottomTrailing) {

            // MARK: Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: Vote Hint (Petunjuk untuk User)
                    // Teks kecil di atas yang memberitahu user cara vote
                    HStack {
                        Image(systemName: "hand.tap")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("tap to vote")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    // MARK: Featured Section (2 Desire Teratas)
                    // Menampilkan 2 desire dengan vote terbanyak dalam card besar full-width.
                    // Card featured punya tombol compose (pencil) untuk merencanakan aktivitas.
                    Text("Featured")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ForEach(featuredActivities) { activity in
                        FeaturedDesireCard(
                            activity: activity,
                            hasVoted: votedIDs.contains(activity.id),   // Cek apakah user sudah vote
                            isAnimating: animatingVoteID == activity.id, // Cek apakah card ini sedang bounce
                            onVote: { toggleVote(for: activity.id) },   // Callback saat tombol vote ditekan
                            onCompose: { onComposeQuest(activity.id) }  // Callback saat tombol compose ditekan
                        )
                        // matchedGeometryEffect: animasi smooth saat card berpindah posisi
                        .matchedGeometryEffect(id: activity.id, in: cardAnimation)
                        .id(activity.id)
                        .onTapGesture {
                            // Saat card di-tap, simpan activity yang dipilih untuk navigasi detail
                            selectedActivity = activity
                        }
                    }
                    .padding(.horizontal)

                    // MARK: Others Section (Desire Lainnya dalam Grid)
                    // Menampilkan sisa desire (selain 2 teratas) dalam layout grid 2 kolom.
                    // Card ini lebih kecil dan tidak punya tombol compose.
                    Text("Others")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // LazyVGrid: grid yang hanya render cell yang terlihat di layar (hemat memori)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(otherActivities) { activity in
                            DesireCard(
                                activity: activity,
                                hasVoted: votedIDs.contains(activity.id),
                                isAnimating: animatingVoteID == activity.id,
                                onVote: { toggleVote(for: activity.id) }
                            )
                            .matchedGeometryEffect(id: activity.id, in: cardAnimation)
                            .id(activity.id)
                            .onTapGesture {
                                selectedActivity = activity
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Spacer di bawah supaya konten tidak tertutup floating button
                    Spacer().frame(height: 80)
                }
                .padding(.top, 8)
                // Animasi spring saat urutan card berubah (karena vote naik/turun)
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: sortedActivities.map(\.id))
            }

            // MARK: Floating Add Button (Tombol Tambah Desire)
            // Tombol bulat orange "+" di pojok kanan bawah untuk membuka form tambah desire baru
            Button {
                showAddDesire = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(
                        Circle()
                            .fill(Color.orange)
                            .shadow(color: .orange.opacity(0.4), radius: 8, y: 4)
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)

            // MARK: Success Popup Overlay
            // Popup yang muncul setelah desire berhasil ditambahkan
            if showAddSuccess {
                addSuccessOverlay
            }
        }
        // MARK: Add Desire Sheet (Bottom Sheet Form)
        // .sheet: menampilkan modal bottom sheet saat showAddDesire = true
        .sheet(isPresented: $showAddDesire) {
            AddDesireSheet(onAdd: { title in
                // Buat object DesireActivity baru dengan data default
                let newDesire = DesireActivity(
                    title: title,
                    subtitle: "",
                    wantCount: 1,              // Mulai dengan 1 vote (dari pembuat)
                    iconName: "triangle.fill",  // Icon default
                    iconColor: "cyan"           // Warna default
                )
                // Tambahkan ke array activities (otomatis update parent karena @Binding)
                activities.append(newDesire)
                // Tutup sheet
                showAddDesire = false
                // Tampilkan popup sukses dengan animasi spring
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showAddSuccess = true
                }
            })
            .presentationDetents([.height(240)])     // Tinggi sheet 240pt
            .presentationDragIndicator(.visible)     // Tampilkan garis drag di atas sheet
        }
    }

    // MARK: - toggleVote() — Logika Vote / Unvote
    /// Fungsi utama untuk menangani vote dan unvote pada sebuah desire.
    /// Alur:
    /// 1. Mulai animasi bounce pada card
    /// 2. Setelah 0.1 detik, update jumlah vote (tambah/kurang)
    /// 3. Setelah 0.4 detik, reset animasi bounce
    private func toggleVote(for id: UUID) {
        // Langkah 1: Mulai animasi bounce pada card yang di-vote
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            animatingVoteID = id
        }

        // Langkah 2: Update vote setelah delay 0.1 detik (supaya animasi bounce terlihat dulu)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                // Cari index activity yang sesuai dengan ID
                if let index = activities.firstIndex(where: { $0.id == id }) {
                    if votedIDs.contains(id) {
                        // Sudah pernah vote → UNVOTE: hapus dari set dan kurangi count
                        votedIDs.remove(id)
                        activities[index].wantCount -= 1
                    } else {
                        // Belum vote → VOTE: tambahkan ke set dan tambah count
                        votedIDs.insert(id)
                        activities[index].wantCount += 1
                    }
                }
            }
        }

        // Langkah 3: Reset animasi bounce setelah 0.4 detik
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animatingVoteID = nil
            }
        }
    }

    // MARK: - addSuccessOverlay — Popup Sukses Setelah Tambah Desire
    /// Overlay popup yang muncul saat desire baru berhasil ditambahkan.
    /// Terdiri dari: background gelap semi-transparan + card popup di tengah.
    /// User bisa menutup dengan tap background atau tekan tombol "OK".
    private var addSuccessOverlay: some View {
        ZStack {
            // Background gelap semi-transparan — tap untuk menutup popup
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showAddSuccess = false
                    }
                }

            // Card popup di tengah layar
            VStack(spacing: 16) {
                // Icon checkmark dengan animasi bounce
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, value: showAddSuccess)

                Text("Desire Added!")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Your desire has been posted.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Tombol OK untuk menutup popup
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showAddSuccess = false
                    }
                } label: {
                    Text("OK")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)     // Material blur effect untuk background card
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            )
            .padding(.horizontal, 40)
            // Animasi masuk: scale dari 0.8 + fade in
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }
}

// MARK: - FeaturedDesireCard (Card Besar untuk 2 Desire Teratas)
/// Card full-width yang menampilkan desire dengan vote tertinggi.
/// Berbeda dengan DesireCard biasa, card ini punya:
/// - Tombol compose (pencil icon) untuk merencanakan aktivitas
/// - Ukuran lebih besar dan lebih menonjol
struct FeaturedDesireCard: View {

    // MARK: - Properties
    /// Data desire activity yang ditampilkan di card ini
    let activity: DesireActivity

    /// Apakah user sudah vote desire ini (untuk menampilkan label "Voted")
    let hasVoted: Bool

    /// Apakah card ini sedang dalam animasi bounce (saat di-vote)
    let isAnimating: Bool

    /// Closure yang dipanggil saat tombol vote ditekan
    let onVote: () -> Void

    /// Closure yang dipanggil saat tombol compose (pencil) ditekan
    let onCompose: () -> Void

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // MARK: Title & Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    // Subtitle hanya tampil jika tidak kosong
                    if !activity.subtitle.isEmpty {
                        Text(activity.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // MARK: Compose Button (Tombol Rencana Aktivitas)
                // Tombol pencil untuk mulai merencanakan/compose quest dari desire ini
                Button {
                    onCompose()
                } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }

            // MARK: Vote Row (Baris Vote: Icon + Count + Label Voted)
            HStack(spacing: 6) {
                // Tombol vote berupa icon
                Button {
                    onVote()
                } label: {
                    Image(systemName: activity.iconName)
                        .font(.caption)
                        .foregroundStyle(iconColor)
                }
                .buttonStyle(.plain)

                // Jumlah vote dengan animasi angka berubah
                Text("\(activity.wantCount) want this")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText()) // Animasi smooth saat angka berubah

                // Label "Voted" muncul jika user sudah vote
                if hasVoted {
                    Text("Voted")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .transition(.scale.combined(with: .opacity)) // Animasi muncul/hilang
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        // Efek bounce: card membesar 5% saat sedang animasi vote
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isAnimating)
    }

    // MARK: - iconColor (Konversi String ke Color)
    /// Mengkonversi nama warna (String) dari data model menjadi SwiftUI Color.
    /// Data model menyimpan warna sebagai String ("orange", "yellow", "cyan")
    /// karena Color tidak bisa langsung disimpan/di-encode.
    private var iconColor: Color {
        switch activity.iconColor {
        case "orange": return .orange
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .gray
        }
    }
}

// MARK: - DesireCard (Card Kecil Grid untuk Desire Lainnya)
/// Card kecil yang ditampilkan dalam grid 2 kolom di bagian "Others".
/// Menampilkan desire yang bukan top 2. Tidak punya tombol compose,
/// hanya bisa di-vote dan di-tap untuk lihat detail.
struct DesireCard: View {

    // MARK: - Properties
    let activity: DesireActivity
    let hasVoted: Bool
    let isAnimating: Bool
    let onVote: () -> Void

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: Title
            Text(activity.title)
                .font(.subheadline)
                .fontWeight(.semibold)

            // MARK: Subtitle (Tampil hanya jika ada)
            if !activity.subtitle.isEmpty {
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: Vote Row (Baris Vote: Icon + Count + Label Voted)
            HStack(spacing: 6) {
                Button {
                    onVote()
                } label: {
                    Image(systemName: activity.iconName)
                        .font(.caption)
                        .foregroundStyle(iconColor)
                }
                .buttonStyle(.plain)

                Text("\(activity.wantCount) want this")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())

                if hasVoted {
                    Text("Voted")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        // Efek bounce: card membesar 8% saat sedang animasi vote (lebih besar dari featured)
        .scaleEffect(isAnimating ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isAnimating)
    }

    // MARK: - iconColor (Konversi String ke Color)
    private var iconColor: Color {
        switch activity.iconColor {
        case "orange": return .orange
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .gray
        }
    }
}

// MARK: - AddDesireSheet (Form Bottom Sheet Tambah Desire Baru)
/// Bottom sheet yang muncul saat user menekan tombol "+" (floating button).
/// Berisi form sederhana dengan text field untuk judul desire
/// dan dua tombol: Cancel dan Add Desire.
struct AddDesireSheet: View {

    // MARK: - Properties
    /// Closure callback yang dipanggil saat user submit desire baru (mengirim judul)
    var onAdd: (String) -> Void

    /// State lokal untuk menyimpan teks yang diketik user di text field
    @State private var desireTitle: String = ""

    /// Environment value untuk menutup sheet secara programatis
    @Environment(\.dismiss) private var dismiss

    // MARK: - Validasi Input
    /// Cek apakah judul yang diketik valid (tidak kosong setelah trim spasi).
    /// Digunakan untuk enable/disable tombol "Add Desire".
    private var isValid: Bool {
        !desireTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: Sheet Title
            Text("New Desire")
                .font(.title3)
                .fontWeight(.bold)

            // MARK: Text Field Input
            // Field tempat user mengetik judul desire baru
            TextField("What activity do you wish for?", text: $desireTitle)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(.systemGray4), lineWidth: 1)
                        )
                )

            // MARK: Action Buttons (Cancel & Add)
            HStack(spacing: 12) {
                // Tombol Cancel — menutup sheet tanpa menambah desire
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color(.systemGray3), lineWidth: 1)
                                )
                        )
                }

                // Tombol Add Desire — memanggil onAdd callback dengan judul yang diketik.
                // Warna berubah: orange jika valid, abu-abu jika belum diisi.
                Button {
                    onAdd(desireTitle)
                } label: {
                    Text("Add Desire")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isValid ? Color.orange : Color(.systemGray4))
                        )
                }
                .disabled(!isValid) // Disable tombol jika input belum valid
                .animation(.easeInOut(duration: 0.2), value: isValid) // Animasi perubahan warna
            }
        }
        .padding(20)
    }
}

// MARK: - Preview
#Preview {
    DesiresView(
        activities: .constant(SampleData.desireActivities),
        selectedActivity: .constant(nil),
        onComposeQuest: { _ in }
    )
}
