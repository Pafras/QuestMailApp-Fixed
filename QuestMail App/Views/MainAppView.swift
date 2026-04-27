//
//  MainAppView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//
//  File ini adalah VIEW UTAMA (root view) dari seluruh aplikasi QuestMail.
//  Semua data dan navigasi dikelola dari sini. File ini berfungsi sebagai
//  "pusat kontrol" yang menghubungkan semua tab dan halaman detail.
//
//  Struktur file:
//  1. QuestTab enum  — Definisi 4 tab aplikasi beserta propertinya
//  2. MainAppView    — View utama: header, tab bar, konten tab, navigasi
//
//  Alur data penting:
//  - MainAppView MEMILIKI semua data (@State) → diteruskan ke child views
//  - Child views mengubah data melalui @Binding atau closure callback
//  - Perubahan data otomatis memperbarui semua view yang terhubung
//

import SwiftUI

// MARK: - QuestTab Enum (Definisi 4 Tab Aplikasi)
/// Enum yang mendefinisikan 4 tab utama di aplikasi.
/// CaseIterable: supaya bisa di-loop dengan ForEach(QuestTab.allCases).
/// rawValue (String): teks yang ditampilkan saat tab aktif.
enum QuestTab: String, CaseIterable {
    case onSchedule = "On Schedule"
    case desires = "Desires"
    case activityPlanning = "Activity Planning"
    
    case history = "History"

    // MARK: icon — SF Symbol untuk Setiap Tab
    var icon: String {
        switch self {
        case .onSchedule: return "calendar.badge.clock"
        case .desires: return "heart.fill"
        case .activityPlanning: return "list.clipboard.fill"
        case .history: return "clock.arrow.circlepath"
        }
    }

    // MARK: tintColor — Warna Tema Setiap Tab
    /// Setiap tab punya warna berbeda untuk membedakan secara visual
    var tintColor: Color {
        switch self {
        case .onSchedule: return .blue
        case .desires: return .orange
        case .activityPlanning: return .green
        case .history: return .purple
        }
    }

    // MARK: categoryTitle — Judul Banner Deskripsi Tab
    var categoryTitle: String {
        switch self {
        case .onSchedule: return "Scheduled Quests"
        case .desires: return "Desires & Wishes"
        case .activityPlanning: return "Activity Planning"
        case .history: return "My Quest History"
        }
    }

    // MARK: categoryDescription — Deskripsi Banner Tab
    var categoryDescription: String {
        switch self {
        case .onSchedule: return "Keep track of your upcoming quests, including scheduled events and meetups."
        case .desires: return "Browse and upvote activities you'd love to try, bundled by popularity."
        case .activityPlanning: return "Organize and plan new activities with your group, from idea to execution."
        case .history: return "Quests you've RSVPed to, upcoming and completed."
        }
    }
}

// MARK: - MainAppView (View Utama Aplikasi — Pusat Kontrol)
/// Root view yang mengelola semua data dan navigasi aplikasi.
/// MainAppView bertanggung jawab untuk:
/// - Menyimpan semua data utama (@State)
/// - Menampilkan tab bar dan konten setiap tab
/// - Menangani navigasi ke halaman detail (quest detail, compose card)
/// - Mengkoordinasikan perubahan data antar tab
struct MainAppView: View {

    // MARK: - Data Utama (Source of Truth)
    // Semua @State di sini adalah "source of truth" — satu-satunya tempat data ini disimpan.
    // Child views menerima data ini lewat @Binding (bisa mengubah) atau let (read-only).

    /// Array semua quest yang terjadwal — ditampilkan di tab On Schedule
    @State private var scheduledQuests: [ScheduledQuest] = SampleData.scheduledQuests

    // MARK: - UI State (Kontrol Tampilan)

    /// Tab yang sedang aktif — menentukan konten yang ditampilkan
    @State private var selectedTab: QuestTab = .onSchedule

    /// Apakah banner deskripsi kategori sedang tampil
    @State private var showCategoryBanner: Bool = true

    /// Namespace untuk animasi perpindahan tab (matchedGeometryEffect)
    @Namespace private var tabAnimation

    // MARK: - Navigation State (Kontrol Navigasi ke Detail)

    /// Quest yang dipilih dari OnScheduleView → navigasi ke ScheduledQuestDetailView
    @State private var selectedQuest: ScheduledQuest?

    /// Desire yang dipilih dari DesiresView (belum dipakai untuk navigasi)
    @State private var selectedActivity: DesireActivity?

    /// Plan yang dipilih dari ActivityPlanningView → navigasi ke ComposeActivityCard
    @State private var selectedPlan: ActivityPlan?

    /// Mengontrol navigasi ke ComposeActivityCard
    @State private var showComposeCard = false

    /// Mode ComposeActivityCard: .compose (dari Desires) atau .editPlan (dari Planning)
    @State private var composeMode: ComposeMode = .compose

    /// Judul awal yang diisi otomatis di ComposeActivityCard
    @State private var composeInitialTitle: String = ""

    /// Aktivitas awal yang diisi otomatis di ComposeActivityCard
    @State private var composeInitialActivity: String = ""

    // MARK: - Data State (Daftar Desire dan Plan)

    /// Array desire activities — ditampilkan di tab Desires
    @State private var desireActivities: [DesireActivity] = SampleData.desireActivities

    /// Array activity plans — ditampilkan di tab Activity Planning
    @State private var activityPlans: [ActivityPlan] = SampleData.activityPlans

    /// ID desire yang sedang di-compose (untuk dihapus dari Desires setelah submit)
    @State private var composingDesireID: UUID?

    /// ID plan yang sedang diedit (untuk dihapus dari Plans setelah move to schedule)
    @State private var editingPlanID: UUID?

    // MARK: - RSVP State

    /// Set berisi ID quest yang sudah di-RSVP oleh user.
    /// Digunakan di OnScheduleView (checkmark), ScheduledQuestDetailView, dan HistoryView.
    @State private var rsvpedQuestIDs: Set<UUID> = []

    // MARK: - Body (Layout Utama)
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Header (Judul Aplikasi)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quest Board")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("The Bridge Tavern")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // MARK: Tab Bar (Custom Horizontal Scroll Tab)
                mailTabBar
                    .padding(.bottom, 4)

                // MARK: Category Banner (Deskripsi Tab Aktif)
                // Banner yang menjelaskan fungsi tab yang sedang aktif.
                // Bisa ditutup dengan tombol X → muncul lagi saat ganti tab.
                if showCategoryBanner {
                    categoryBanner
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                }

                // MARK: Tab Content (Konten Sesuai Tab Aktif)
                // Switch case menampilkan view yang berbeda sesuai tab yang dipilih.
                // Setiap child view menerima data dari MainAppView.
                Group {
                    switch selectedTab {
                    case .onSchedule:
                        OnScheduleView(
                            quests: scheduledQuests,
                            selectedQuest: $selectedQuest,
                            rsvpedQuestIDs: $rsvpedQuestIDs,
                            // Closure callback: dipanggil saat RSVP/cancel di OnScheduleView.
                            // Menggunakan fungsi handleRSVPChange yang sama dengan detail view.
                            onRSVPChange: { questID, isJoining in
                                handleRSVPChange(questID: questID, isJoining: isJoining)
                            }
                        )
                    case .desires:
                        DesiresView(
                            activities: $desireActivities,
                            selectedActivity: $selectedActivity,
                            // Closure: dipanggil saat user tekan compose (pencil) di featured card.
                            // Membuka ComposeActivityCard dalam mode compose.
                            onComposeQuest: { desireID in
                                composeMode = .compose
                                composingDesireID = desireID
                                // find the desire by id and store its wantCount
                                    // so it can become interestedCount in the ActivityPlan
                                    if let desireItem = desireActivities.first(where: { eachDesire in eachDesire.id == desireID }) {
                                        composingDesireWantCount = desireItem.wantCount
                                    }
                                composeInitialTitle = ""
                                composeInitialActivity = ""
                                showComposeCard = true
                            }
                        )
                    case .activityPlanning:
                        ActivityPlanningView(
                            plans: activityPlans,
                            selectedPlan: $selectedPlan
                        )
                    case .history:
                        // passes the full quest array + the set of RSVPed IDs
                        // HistoryView will filter internally to find the ones the user joined
                        HistoryView(
                            questsData: scheduledQuests,         // source: MainAppView's @State array
                            rsvpedQuestIDs: rsvpedQuestIDs       // source: MainAppView's @State set — NOT a binding, read-only here
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            }

            // MARK: Navigasi ke ComposeActivityCard
            // Terbuka saat showComposeCard = true (dari Desires atau Activity Planning).
            // onSubmit callback menangani apa yang terjadi setelah form di-submit.
            .navigationDestination(isPresented: $showComposeCard) {
                ComposeActivityCard(
                    mode: composeMode,
                    initialTitle: composeInitialTitle,
                    initialActivity: composeInitialActivity,
                    onSubmit: { plan in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                            if composeMode == .compose {
                                // ALUR DARI DESIRES:
                                // 1. Tambahkan plan baru ke daftar plans
                                // 2. Hapus desire yang sudah di-compose
                                // 3. Pindahkan user ke tab Activity Planning
                                activityPlans.append(plan)
                                if let desireID = composingDesireID {
                                    desireActivities.removeAll { $0.id == desireID }
                                    composingDesireID = nil
                                }
                                selectedTab = .activityPlanning
                            } else {
                                // ALUR DARI ACTIVITY PLANNING:
                                // 1. Hapus plan yang sudah diedit dari daftar plans
                                // 2. Buat ScheduledQuest baru dari data plan
                                // 3. Tambahkan ke scheduledQuests
                                // 4. Pindahkan user ke tab On Schedule
                                if let planID = editingPlanID {
                                    activityPlans.removeAll { $0.id == planID }
                                    editingPlanID = nil
                                }
                                let newQuest = createScheduledQuest(from: plan)
                                scheduledQuests.append(newQuest)
                                selectedTab = .onSchedule
                            }
                        }
                    }
                )
            }

            // MARK: Deteksi Plan Dipilih → Buka ComposeActivityCard
            // .onChange memantau perubahan selectedPlan.
            // Saat user tap plan di ActivityPlanningView, selectedPlan diisi
            // → trigger ini membuka ComposeActivityCard dalam mode editPlan.
            .onChange(of: selectedPlan) { _, plan in
                if let plan {
                    composeMode = .editPlan
                    editingPlanID = plan.id
                    composeInitialTitle = plan.title
                    composeInitialActivity = plan.activity
                    selectedPlan = nil           // Reset supaya bisa dipilih lagi
                    showComposeCard = true       // Navigasi ke ComposeActivityCard
                }
            }

            // MARK: Navigasi ke ScheduledQuestDetailView
            // Terbuka saat selectedQuest diisi (user tap quest di OnScheduleView).
            // navigationDestination(item:) otomatis membuka view saat item tidak nil.
            .navigationDestination(item: $selectedQuest) { questItem in
                ScheduledQuestDetailView(
                    onRSVPChange: { questID, isJoining in
                        handleRSVPChange(questID: questID, isJoining: isJoining)
                    },
                    questData: questItem,
                    rsvpedQuestIDs: $rsvpedQuestIDs
                )
            }
        }
    }

    // MARK: - mailTabBar — Custom Tab Bar (Horizontal Scroll)
    /// Tab bar horizontal yang bisa di-scroll. Desainnya terinspirasi dari Apple Mail.
    /// Tab aktif: capsule berwarna dengan teks. Tab tidak aktif: circle abu-abu hanya icon.
    /// matchedGeometryEffect membuat animasi background berpindah smooth antar tab.
    private var mailTabBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuestTab.allCases, id: \.self) { tab in
                        let isSelected = selectedTab == tab

                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                                selectedTab = tab
                                showCategoryBanner = true  // Tampilkan banner saat ganti tab
                            }
                        } label: {
                            HStack(spacing: 6) {
                                // Icon selalu tampil
                                Image(systemName: tab.icon)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                // Teks label hanya tampil saat tab aktif
                                if isSelected {
                                    Text(tab.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .transition(.asymmetric(
                                            insertion: .push(from: .leading).combined(with: .opacity),
                                            removal: .push(from: .trailing).combined(with: .opacity)
                                        ))
                                }
                            }
                            .foregroundStyle(isSelected ? .white : .secondary)
                            .padding(.horizontal, isSelected ? 16 : 0)
                            .padding(.vertical, 10)
                            .frame(width: isSelected ? nil : 42, height: 42)
                            .background {
                                if isSelected {
                                    // Tab aktif: capsule berwarna (background berpindah smooth)
                                    Capsule()
                                        .fill(tab.tintColor)
                                        .matchedGeometryEffect(id: "tabBg", in: tabAnimation)
                                } else {
                                    // Tab tidak aktif: circle abu-abu
                                    Circle()
                                        .fill(Color(.systemGray5))
                                        .matchedGeometryEffect(id: "tab_\(tab.rawValue)", in: tabAnimation)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .id(tab)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            // Auto-scroll ke tab yang dipilih supaya selalu terlihat
            .onChange(of: selectedTab) { _, newTab in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    proxy.scrollTo(newTab, anchor: .center)
                }
            }
        }
    }

    // MARK: - categoryBanner — Banner Deskripsi Kategori Tab
    /// Banner info yang muncul di bawah tab bar, menjelaskan fungsi tab yang aktif.
    /// Berisi judul + deskripsi + tombol X untuk menutup.
    /// Warna mengikuti tintColor tab yang aktif.
    private var categoryBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedTab.categoryTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(selectedTab.tintColor)

                Text(selectedTab.categoryDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Tombol X untuk menutup banner
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showCategoryBanner = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(selectedTab.tintColor.opacity(0.7))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(selectedTab.tintColor.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(selectedTab.tintColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(selectedTab.tintColor.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
    }

    // MARK: - createScheduledQuest() — Konversi ActivityPlan ke ScheduledQuest
    /// Mengubah ActivityPlan menjadi ScheduledQuest.
    /// Dipanggil saat plan di-submit dari ComposeActivityCard dalam mode editPlan.
    /// Menggabungkan tanggal (dari plan.date) dan waktu (dari plan.time) menjadi satu Date.
    private func createScheduledQuest(from plan: ActivityPlan) -> ScheduledQuest {
        // Gabungkan komponen tanggal dan waktu dari 2 Date yang berbeda
        let cal = Calendar.current
        let dayComponents = cal.dateComponents([.year, .month, .day], from: plan.date)
        let timeComponents = cal.dateComponents([.hour, .minute], from: plan.time)
        var combined = DateComponents()
        combined.year = dayComponents.year
        combined.month = dayComponents.month
        combined.day = dayComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        let scheduledDate = cal.date(from: combined) ?? plan.date

        return ScheduledQuest(
            title: plan.title,
            venue: plan.place.isEmpty ? "TBD" : plan.place,  // "TBD" jika lokasi belum diisi
            scheduledDate: scheduledDate,
            iconName: "star.fill",
            participantType: plan.participantType,
            maxParticipants: plan.maxParticipants,
            rsvpCount: 0,                  // Mulai dari 0 — belum ada yang RSVP
            activityDetail: plan.activity,
            reward: plan.reward,
            organizer: plan.organizer
        )
    }

    // MARK: - handleRSVPChange() — Update Jumlah RSVP di Data Utama
    /// Fungsi callback yang dipanggil saat user RSVP atau cancel RSVP.
    /// Digunakan oleh: OnScheduleView (swipe) dan ScheduledQuestDetailView (tombol).
    /// Mencari quest berdasarkan ID lalu menambah/mengurangi rsvpCount.
    private func handleRSVPChange(questID: UUID, isJoining: Bool) {
        guard let questIndex = scheduledQuests.firstIndex(where: { $0.id == questID }) else { return }
        if isJoining {
            scheduledQuests[questIndex].rsvpCount += 1
        } else {
            scheduledQuests[questIndex].rsvpCount -= 1
        }
    }
}

// MARK: - Preview
#Preview {
    MainAppView()
}
