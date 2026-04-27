//
//  Models.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//
//  File ini berisi semua data model (struktur data) yang digunakan di seluruh aplikasi.
//  Setiap struct/enum di sini mendefinisikan bentuk data yang ditampilkan di UI.
//
//  Struktur file:
//  1. ScheduleSection   — Enum untuk mengelompokkan quest berdasarkan minggu/bulan
//  2. ParticipantType   — Enum tipe partisipan (Open / Limited)
//  3. ScheduledQuest    — Model data quest yang sudah terjadwal
//  4. DesireActivity    — Model data desire (aktivitas yang diinginkan)
//  5. RSVPStatus        — Enum status RSVP (Yes / No / Idk)
//  6. ActivityPlan      — Model data rencana aktivitas yang sedang diorganisir
//  7. RSVPResponse      — Model respon RSVP dengan jumlah orang per status
//  8. SampleData        — Data dummy/contoh untuk preview dan testing
//

import Foundation

// MARK: - ScheduleSection (Pengelompokan Quest Berdasarkan Waktu)
/// Enum ini digunakan untuk mengelompokkan quest di tab "On Schedule"
/// menjadi section-section berdasarkan waktu: "This Week", "Next Week", atau nama bulan.
/// Conform ke Hashable supaya bisa digunakan sebagai key di ForEach dan Set.
enum ScheduleSection: Hashable {
    case thisWeek                          // Quest yang jatuh di minggu ini
    case nextWeek                          // Quest yang jatuh di minggu depan
    case month(year: Int, month: Int)      // Quest di bulan tertentu (untuk yang lebih jauh)

    // MARK: title — Teks yang Ditampilkan di Section Header
    /// Menghasilkan judul section yang ditampilkan di UI.
    /// .thisWeek → "This Week", .nextWeek → "Next Week", .month → "May 2026"
    var title: String {
        switch self {
        case .thisWeek: return "This Week"
        case .nextWeek: return "Next Week"
        case .month(let year, let month):
            // Menggunakan DateFormatter untuk mengubah angka bulan jadi nama bulan
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return ""
        }
    }

    // MARK: sortOrder — Urutan untuk Sorting Section
    /// Angka untuk mengurutkan section dari yang paling dekat ke paling jauh.
    /// thisWeek = 0, nextWeek = 1, bulan-bulan berikutnya = 2+
    var sortOrder: Int {
        switch self {
        case .thisWeek: return 0
        case .nextWeek: return 1
        case .month(let year, let month): return 2 + year * 12 + month
        }
    }

    // MARK: from(date:) — Menentukan Section dari Sebuah Tanggal
    /// Static function yang menentukan sebuah Date masuk ke section mana.
    /// Logika: cek apakah tanggal jatuh di minggu ini, minggu depan, atau bulan lainnya.
    static func from(date: Date) -> ScheduleSection {
        let cal = Calendar.current
        let now = Date()

        // Ambil interval minggu ini (Senin–Minggu atau sesuai locale)
        guard let thisWeekInterval = cal.dateInterval(of: .weekOfYear, for: now) else {
            // Fallback: kalau gagal, gunakan bulan
            let c = cal.dateComponents([.year, .month], from: date)
            return .month(year: c.year ?? 2026, month: c.month ?? 1)
        }

        // Hitung batas awal dan akhir minggu depan
        let startOfNextWeek = cal.date(byAdding: .weekOfYear, value: 1, to: thisWeekInterval.start)!
        let endOfNextWeek = cal.date(byAdding: .weekOfYear, value: 1, to: startOfNextWeek)!

        // Tentukan section berdasarkan perbandingan tanggal
        if date < startOfNextWeek {
            return .thisWeek
        } else if date < endOfNextWeek {
            return .nextWeek
        } else {
            let c = cal.dateComponents([.year, .month], from: date)
            return .month(year: c.year ?? 2026, month: c.month ?? 1)
        }
    }
}

// MARK: - ParticipantType (Tipe Partisipan: Open atau Limited)
/// Menentukan apakah sebuah quest terbuka untuk semua orang atau dibatasi jumlahnya.
/// - .open: siapa saja bisa join, tidak ada batas peserta
/// - .limited: ada batas maksimal peserta (maxParticipants)
enum ParticipantType: String, Hashable {
    case open = "Open"
    case limited = "Limited"
}

// MARK: - ScheduledQuest (Model Quest yang Sudah Terjadwal)
/// Data model untuk quest yang sudah memiliki jadwal pasti dan tampil di tab "On Schedule".
/// Identifiable: supaya bisa digunakan di ForEach tanpa perlu specify id.
/// Hashable: supaya bisa digunakan di NavigationDestination dan Set.
struct ScheduledQuest: Identifiable, Hashable {
    let id = UUID()                        // ID unik otomatis — setiap quest punya ID berbeda
    let title: String                      // Judul quest (contoh: "Futsal")
    let venue: String                      // Lokasi/tempat (contoh: "Apple Futsal Academy")
    let scheduledDate: Date                // Tanggal dan waktu quest dijadwalkan
    let iconName: String                   // Nama SF Symbol icon (contoh: "sportscourt.fill")
    let participantType: ParticipantType   // Tipe partisipan: Open atau Limited
    let maxParticipants: Int?              // Maksimal peserta — nil jika Open (tidak dibatasi)
    var rsvpCount: Int                     // Jumlah orang yang sudah RSVP (var karena bisa berubah)
    let activityDetail: String             // Deskripsi detail aktivitas
    let reward: String                     // Apa yang didapat peserta dari quest ini
    let organizer: String                  // Siapa yang mengorganisir quest ini

    // MARK: formattedDate — Format Tanggal untuk Tampilan (dd/MM)
    /// Mengubah scheduledDate menjadi format "24/04" untuk ditampilkan di QuestRow
    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM"
        return f.string(from: scheduledDate)
    }

    // MARK: formattedTime — Format Waktu untuk Tampilan (h:mm a)
    /// Mengubah scheduledDate menjadi format "6:00 PM" untuk ditampilkan di QuestRow
    var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: scheduledDate)
    }
}

// MARK: - DesireActivity (Model Desire/Keinginan Aktivitas)
/// Data model untuk aktivitas yang diinginkan user, tampil di tab "Desires".
/// User bisa vote desire ini. Desire dengan vote terbanyak jadi Featured.
struct DesireActivity: Identifiable, Hashable {
    let id = UUID()          // ID unik otomatis
    let title: String        // Judul desire (contoh: "Salsa Dance")
    let subtitle: String     // Subtitle/keterangan tambahan (contoh: nama pengusul)
    var wantCount: Int       // Jumlah vote — var karena berubah saat user vote/unvote
    let iconName: String     // Nama SF Symbol icon
    let iconColor: String    // Warna icon dalam bentuk String ("orange", "yellow", "cyan")
}

// MARK: - RSVPStatus (Status RSVP: Yes, No, atau Idk)
/// Enum untuk pilihan respon RSVP di Activity Planning.
/// CaseIterable: supaya bisa di-loop semua case-nya.
enum RSVPStatus: String, CaseIterable {
    case yes = "Yes"     // User mau ikut
    case no = "No"       // User tidak bisa ikut
    case idk = "Idk"     // User belum yakin
}

// MARK: - ActivityPlan (Model Rencana Aktivitas yang Sedang Diorganisir)
/// Data model untuk aktivitas yang sedang dalam tahap perencanaan.
/// Tampil di tab "Activity Planning". Setelah semua detail diisi,
/// bisa dipindahkan ke "On Schedule" menjadi ScheduledQuest.
struct ActivityPlan: Identifiable, Hashable {
    let id = UUID()                                       // ID unik otomatis
    let title: String                                     // Judul rencana (contoh: "Taekwondo")
    let organizer: String                                 // Nama organizer + jumlah yang tertarik
    let interestedCount: Int                              // Jumlah orang yang tertarik
    let rsvpStatuses: [RSVPResponse]                      // Array respon RSVP (berapa Yes, No, Idk)
    var activity: String = ""                             // Deskripsi aktivitas (diisi di ComposeCard)
    var place: String = ""                                // Lokasi (diisi di ComposeCard)
    var reward: String = ""                               // Reward/hadiah (diisi di ComposeCard)
    var date: Date = Date()                               // Tanggal rencana
    var time: Date = Date()                               // Waktu rencana
    var participantType: ParticipantType = .open          // Default: Open (siapa saja bisa ikut)
    var maxParticipants: Int? = nil                       // Batas peserta — nil jika Open
}

// MARK: - RSVPResponse (Respon RSVP dengan Jumlah Orang)
/// Menyimpan satu baris respon RSVP: status apa dan berapa orang.
/// Contoh: RSVPResponse(status: .yes, count: 3) berarti 3 orang jawab "Yes"
struct RSVPResponse: Identifiable, Hashable {
    let id = UUID()          // ID unik otomatis
    let status: RSVPStatus   // Status: .yes, .no, atau .idk
    let count: Int           // Berapa orang yang memilih status ini
}

// MARK: - SampleData (Data Contoh untuk Preview dan Testing)
/// Struct berisi data dummy/contoh yang digunakan untuk:
/// - SwiftUI Preview (#Preview) di setiap view
/// - Sebagai data awal saat app baru dibuka (sebelum ada backend)
struct SampleData {

    // MARK: makeDate() — Helper Membuat Date dari Komponen
    /// Fungsi helper untuk membuat Date dari komponen tanggal dan waktu.
    /// Memudahkan pembuatan sample data tanpa harus menulis DateComponents berulang.
    private static func makeDate(day: Int, month: Int, year: Int = 2026, hour: Int = 18, minute: Int = 0) -> Date {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day
        c.hour = hour
        c.minute = minute
        return Calendar.current.date(from: c) ?? Date()
    }

    // MARK: scheduledQuests — Data Contoh Quest Terjadwal
    /// Array berisi 5 quest contoh yang tampil di tab "On Schedule".
    /// Mencakup berbagai tipe: Open dan Limited, dengan tanggal berbeda-beda.
    static let scheduledQuests: [ScheduledQuest] = [
        ScheduledQuest(
            title: "Finesse your first moves",
            venue: "Apple Dance Academy - Agung",
            scheduledDate: makeDate(day: 24, month: 4, hour: 18, minute: 0),
            iconName: "figure.dance",
            participantType: .open,
            maxParticipants: nil,
            rsvpCount: 5,
            activityDetail: "A beginner-friendly Latin dance session covering basic salsa footwork and partner movement.",
            reward: "You'll walk away knowing your first 3 salsa moves and feeling less awkward on the dancefloor.",
            organizer: "Pafras"
        ),
        ScheduledQuest(
            title: "Futsal",
            venue: "Apple Futsal Academy - Arjuna Court",
            scheduledDate: makeDate(day: 25, month: 4, hour: 19, minute: 15),
            iconName: "sportscourt.fill",
            participantType: .limited,
            maxParticipants: 14,
            rsvpCount: 10,
            activityDetail: "Casual 5v5 futsal. Balanced teams will be sorted on the day.",
            reward: "A solid sweat, bragging rights, and maybe a post-game drink.",
            organizer: "Agung"
        ),
        ScheduledQuest(
            title: "Bouldering",
            venue: "Apple Bouldering Academy - Canggu",
            scheduledDate: makeDate(day: 26, month: 4, hour: 18, minute: 30),
            iconName: "figure.climbing",
            participantType: .limited,
            maxParticipants: 8,
            rsvpCount: 6,
            activityDetail: "Indoor bouldering for all levels. Instructors on hand for first-timers.",
            reward: "Upper body gains and a new hobby that will haunt your weekend plans.",
            organizer: "Pafras"
        ),
        ScheduledQuest(
            title: "Pafras's Birthday",
            venue: "Filadelfia Sushi Kerobokan",
            scheduledDate: makeDate(day: 30, month: 4, hour: 18, minute: 0),
            iconName: "gift.fill",
            participantType: .open,
            maxParticipants: nil,
            rsvpCount: 12,
            activityDetail: "Dinner to celebrate Pafras turning another year older and somehow wiser.",
            reward: "Good food, good people, and a free excuse to skip the gym.",
            organizer: "Pafras"
        ),
        ScheduledQuest(
            title: "UCL Final",
            venue: "Sports Bar - Seminyak",
            scheduledDate: makeDate(day: 10, month: 5, hour: 19, minute: 45),
            iconName: "soccerball",
            participantType: .limited,
            maxParticipants: 20,
            rsvpCount: 18,
            activityDetail: "Watching the UEFA Champions League Final together. Jerseys encouraged.",
            reward: "Shared suffering or shared glory, depending on who makes the final.",
            organizer: "Agung"
        ),
    ]

    // MARK: desireActivities — Data Contoh Desire Activities
    /// Array berisi 8 desire contoh yang tampil di tab "Desires".
    /// wantCount menentukan urutan: yang tertinggi jadi Featured (2 teratas).
    static let desireActivities: [DesireActivity] = [
        DesireActivity(title: "Salsa Dance", subtitle: "Pafras", wantCount: 12, iconName: "triangle.fill", iconColor: "orange"),
        DesireActivity(title: "Mini Soccer", subtitle: "", wantCount: 12, iconName: "triangle.fill", iconColor: "orange"),
        DesireActivity(title: "Self Defence Class", subtitle: "", wantCount: 12, iconName: "triangle.fill", iconColor: "yellow"),
        DesireActivity(title: "Weekly Board Games", subtitle: "", wantCount: 4, iconName: "triangle.fill", iconColor: "yellow"),
        DesireActivity(title: "Animation", subtitle: "", wantCount: 7, iconName: "triangle.fill", iconColor: "cyan"),
        DesireActivity(title: "Balinese Music Lesson", subtitle: "", wantCount: 4, iconName: "triangle.fill", iconColor: "cyan"),
        DesireActivity(title: "Book Sharing", subtitle: "", wantCount: 7, iconName: "triangle.fill", iconColor: "cyan"),
        DesireActivity(title: "Monthly FIFA Tournament", subtitle: "", wantCount: 4, iconName: "triangle.fill", iconColor: "cyan"),
    ]

    // MARK: activityPlans — Data Contoh Activity Plans
    /// Array berisi 4 rencana aktivitas contoh yang tampil di tab "Activity Planning".
    /// Masing-masing bisa diedit dan dipindahkan ke On Schedule setelah lengkap.
    static let activityPlans: [ActivityPlan] = [
        ActivityPlan(title: "Taekwondo", organizer: "Richie", interestedCount: 8, rsvpStatuses: [
            RSVPResponse(status: .yes, count: 3),
            RSVPResponse(status: .no, count: 2),
            RSVPResponse(status: .idk, count: 3),
        ]),
        ActivityPlan(title: "Apple Academy Marathon", organizer: "Marcus", interestedCount: 8, rsvpStatuses: []),
        ActivityPlan(title: "Cooking Class Vol. 3", organizer: "Lewandowski", interestedCount: 8, rsvpStatuses: []),
        ActivityPlan(title: "Jamming Apple Bali Band", organizer: "Bellingham", interestedCount: 8, rsvpStatuses: []),
    ]
}
