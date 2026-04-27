//
//  ComposeActivityCard.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 21/04/26.
//
//  File ini berisi form untuk membuat/mengedit Activity Card.
//  Digunakan di 2 skenario berbeda (2 mode):
//  1. Compose mode  — Dari tab Desires: membuat rencana baru dari desire yang ada
//  2. EditPlan mode — Dari tab Activity Planning: mengisi detail plan lalu pindah ke schedule
//
//  Struktur file:
//  1. ComposeMode         — Enum yang menentukan mode form (compose / editPlan)
//  2. ComposeActivityCard — View utama form dengan semua field input
//  3. TimePickerSheet     — Bottom sheet untuk memilih waktu
//  4. TimePicker15Min     — UIKit wrapper untuk time picker dengan interval 15 menit
//

import SwiftUI

// MARK: - ComposeMode (Mode Form: Compose atau Edit Plan)
/// Menentukan konteks form ini dibuka dari mana, yang mempengaruhi:
/// - Validasi: compose hanya butuh title, editPlan butuh semua field
/// - Warna tema: compose = teal, editPlan = hijau
/// - Teks tombol: "Submit Quest" vs "Move to Schedule"
/// - Aksi setelah submit: tambah ke plans vs pindah ke schedule
enum ComposeMode {
    case compose      // Dari tab Desires — hanya title yang wajib diisi
    case editPlan     // Dari tab Activity Planning — semua field wajib diisi
}

// MARK: - ComposeActivityCard (Form Utama Buat/Edit Activity)
/// View form full-page untuk membuat atau mengedit Activity Card.
/// Berisi field: Date, Time, Title, Activity, Reward, Place, Participants, Host.
struct ComposeActivityCard: View {

    // MARK: - Theme (Warna Tema Berdasarkan Mode)
    /// Warna utama berubah sesuai mode: teal untuk compose, hijau untuk editPlan.
    /// Ini membantu user membedakan secara visual sedang di mode apa.
    private var accentTeal: Color {
        mode == .compose
            ? Color(red: 0.24, green: 0.46, blue: 0.38)  // Teal gelap
            : Color(red: 0.13, green: 0.54, blue: 0.13)  // Hijau
    }
    /// Versi terang dari warna aksen — dipakai untuk background field
    private var lightTeal: Color {
        accentTeal.opacity(0.08)
    }

    // MARK: - Properties
    /// Environment untuk menutup view ini (kembali ke halaman sebelumnya)
    @Environment(\.dismiss) private var dismiss

    /// Mode form: .compose (dari Desires) atau .editPlan (dari Activity Planning)
    let mode: ComposeMode

    /// Closure callback yang dipanggil saat form di-submit.
    /// Mengirim ActivityPlan yang sudah diisi ke MainAppView.
    var onSubmit: ((ActivityPlan) -> Void)?

    // MARK: - State Properties (Data Input Form)
    /// Setiap @State menyimpan nilai yang diketik user di masing-masing field.

    /// Judul quest — bisa diisi otomatis dari desire title (initialTitle)
    @State private var questTitle: String

    /// Deskripsi aktivitas — bisa diisi otomatis dari plan (initialActivity)
    @State private var activity: String

    /// Apa yang didapat peserta dari quest ini
    @State private var reward: String = ""

    /// Nama host/penyelenggara
    @State private var hostedBy: String = ""

    /// Lokasi/link lokasi
    @State private var place: String = ""

    /// Tanggal yang dipilih — default hari ini
    @State private var selectedDate = Date()

    /// Waktu yang dipilih — default 00:00 (midnight)
    @State private var selectedTime: Date = {
        let cal = Calendar.current
        var c = cal.dateComponents([.year, .month, .day], from: Date())
        c.hour = 0
        c.minute = 0
        return cal.date(from: c) ?? Date()
    }()

    /// Apakah ada batas jumlah peserta (toggle Open/Limited)
    @State private var hasParticipantLimit = false

    /// Jumlah maksimal peserta — hanya relevan jika hasParticipantLimit = true
    @State private var participantCount: Int = 2

    /// Mengontrol tampilan popup sukses setelah submit
    @State private var showSuccess = false

    /// Mengontrol tampilan bottom sheet time picker
    @State private var showTimePicker = false

    /// ID unik untuk DatePicker — di-regenerate setiap kali tanggal berubah
    /// agar DatePicker collapse otomatis setelah user pilih tanggal
    @State private var datePickerId = UUID()

    // MARK: - init (Custom Initializer)
    /// Custom init untuk mengisi nilai awal title dan activity.
    /// Diperlukan karena @State harus diinisialisasi lewat State(initialValue:)
    /// saat nilainya berasal dari parameter init.
    /// Jumlah orang yang tertarik (dari wantCount desire atau interestedCount plan)
    var interestedCount: Int = 0

    init(mode: ComposeMode = .compose, initialTitle: String = "", initialActivity: String = "", interestedCount: Int = 0, onSubmit: ((ActivityPlan) -> Void)? = nil) {
        self.mode = mode
        self.interestedCount = interestedCount
        self.onSubmit = onSubmit
        _questTitle = State(initialValue: initialTitle)
        _activity = State(initialValue: initialActivity)
    }

    // MARK: - Computed Properties (Validasi dan Teks Dinamis)

    /// Cek apakah form sudah lengkap dan boleh di-submit.
    /// Compose mode: hanya butuh title. EditPlan mode: semua field wajib.
    private var isFormComplete: Bool {
        switch mode {
        case .compose:
            return !questTitle.trimmingCharacters(in: .whitespaces).isEmpty
        case .editPlan:
            return !questTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !activity.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !reward.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !hostedBy.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !place.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    /// Teks tombol submit — berubah sesuai mode
    private var buttonTitle: String {
        mode == .compose ? "Submit Quest" : "Move to Schedule"
    }

    /// Judul popup sukses — berubah sesuai mode
    private var successTitle: String {
        mode == .compose ? "Quest Submitted!" : "Moved to Schedule!"
    }

    /// Pesan popup sukses — berubah sesuai mode
    private var successMessage: String {
        mode == .compose
            ? "Your activity card has been\nsuccessfully added."
            : "Your activity is now\non the schedule."
    }

    // MARK: - Body (Layout Utama Form)
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: Scrollable Form Fields
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // MARK: Page Title
                        Text("Activity Card")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(accentTeal)
                            .padding(.top, 8)

                        // MARK: Date Picker Row
                        dateRow

                        // MARK: Time Picker Row
                        timeRow

                        // MARK: Title Field (Judul Quest)
                        sectionField(
                            header: "TITLE",
                            placeholder: "Name your quest",
                            text: $questTitle,
                            isMultiline: false
                        )

                        // MARK: Activity Field (Deskripsi Aktivitas)
                        sectionField(
                            header: "ACTIVITY",
                            placeholder: "What will you be doing ?",
                            text: $activity,
                            isMultiline: true
                        )

                        // MARK: Reward Field (Apa yang Didapat Peserta)
                        sectionField(
                            header: "WHAT YOU\u{2019}LL WALK AWAY WITH",
                            placeholder: "The reward for joining",
                            text: $reward,
                            isMultiline: true
                        )

                        // MARK: Place Field (Lokasi dengan Icon Map)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PLACE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(accentTeal.opacity(0.7))
                                .textCase(.uppercase)

                            HStack(spacing: 10) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(accentTeal)
                                TextField("Paste location link (e.g. Google Maps)", text: $place)
                                    .keyboardType(.URL)
                                    .textContentType(.URL)
                                    .autocapitalization(.none)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                        }

                        // MARK: Participants Section (Open / Limited + Counter)
                        participantRow

                        // MARK: Host Field (Siapa Penyelenggara)
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

                // MARK: Submit Button (Tombol Submit di Bawah)
                // Disabled jika form belum lengkap. Warna berubah: aksen jika valid, abu-abu jika belum.
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showSuccess = true
                    }
                } label: {
                    Text(buttonTitle)
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

            // MARK: Success Overlay (Popup Sukses Setelah Submit)
            if showSuccess {
                successOverlay
            }
        }
        // Sembunyikan back button default dan ganti dengan custom
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

    // MARK: - submitAndDismiss() — Buat ActivityPlan dan Kirim ke Parent
    /// Membuat object ActivityPlan dari semua data yang diisi di form,
    /// lalu memanggil onSubmit callback untuk mengirim data ke MainAppView,
    /// dan menutup halaman ini.
    private func submitAndDismiss() {
        let newPlan = ActivityPlan(
            title: questTitle,
            organizer: hostedBy,
            interestedCount: interestedCount,
            rsvpStatuses: [],
            activity: activity,
            place: place,
            reward: reward,
            date: selectedDate,
            time: selectedTime,
            participantType: hasParticipantLimit ? .limited : .open,
            maxParticipants: hasParticipantLimit ? participantCount : nil
        )
        onSubmit?(newPlan)   // Kirim data ke MainAppView via closure
        dismiss()            // Tutup halaman ini
    }

    // MARK: - dateRow — Baris Pemilih Tanggal
    /// Menampilkan label "Date" dengan icon kalender dan native DatePicker.
    /// datePickerId di-regenerate setiap kali tanggal berubah supaya picker
    /// otomatis collapse (trik SwiftUI karena tidak ada API resmi untuk ini).
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
                    datePickerId = UUID()  // Force re-create picker → auto-collapse
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

    // MARK: - timeRow — Baris Pemilih Waktu
    /// Menampilkan label "Time" dan waktu yang dipilih.
    /// Saat di-tap, membuka TimePickerSheet (bottom sheet) dengan interval 15 menit.
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

                // Menampilkan waktu yang sudah dipilih
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

    // MARK: - participantRow — Bagian Pemilihan Tipe Partisipan
    /// Menampilkan segmented control Open/Limited dan counter jumlah peserta.
    /// Jika user pilih "Limited", muncul counter +/- untuk mengatur maksimal peserta.
    /// Minimum peserta = 2 (tidak bisa kurang).
    private var participantRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PARTICIPANTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accentTeal.opacity(0.7))
                .textCase(.uppercase)

            // MARK: Open / Limited Segmented Control
            // Dua tombol bersebelahan: "Open" dan "Limited"
            HStack(spacing: 0) {
                participantOption(
                    title: "Open",
                    subtitle: "Anyone can join",
                    icon: "person.3.fill",
                    isSelected: !hasParticipantLimit
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        hasParticipantLimit = false
                        participantCount = 2       // Reset counter saat kembali ke Open
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

            // MARK: Participant Counter (Muncul Hanya Jika Limited)
            // Tombol +/- untuk mengatur jumlah maksimal peserta
            if hasParticipantLimit {
                HStack {
                    Text("Max participants")
                        .font(.body)

                    Spacer()

                    HStack(spacing: 16) {
                        // Tombol minus — disabled jika sudah di minimum (2)
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

                        // Angka jumlah peserta dengan animasi angka berubah
                        Text("\(participantCount)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(minWidth: 30)
                            .contentTransition(.numericText())

                        // Tombol plus — tidak ada batas atas
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
                // Animasi masuk dari atas + fade, keluar dengan scale + fade
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - successOverlay — Popup Sukses Setelah Submit
    /// Overlay popup yang muncul setelah submit berhasil.
    /// Menampilkan icon checkmark, pesan sukses, dan tombol "Done".
    /// Setelah ditutup, memanggil submitAndDismiss() untuk mengirim data dan kembali.
    private var successOverlay: some View {
        ZStack {
            // Background gelap semi-transparan — tap untuk menutup
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSuccess = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        submitAndDismiss()
                    }
                }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(accentTeal)
                    .symbolEffect(.bounce, value: showSuccess)

                Text(successTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(accentTeal)

                Text(successMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Tombol Done — menutup popup dan submit data
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSuccess = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        submitAndDismiss()
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

    // MARK: - participantOption() — Tombol Opsi Partisipan (Reusable)
    /// Fungsi helper yang membuat satu tombol opsi (Open atau Limited).
    /// Digunakan 2 kali di participantRow untuk membuat segmented control.
    /// Parameter isSelected menentukan apakah tombol ini sedang aktif (highlight).
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

    // MARK: - sectionField() — Komponen Field Input (Reusable)
    /// Fungsi helper yang membuat satu section field lengkap (header + input).
    /// Digunakan berulang kali untuk Title, Activity, Reward, dan Host field.
    /// Parameter isMultiline menentukan apakah menggunakan TextEditor (multi-baris)
    /// atau TextField (satu baris).
    private func sectionField(header: String, placeholder: String, text: Binding<String>, isMultiline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header label
            Text(header)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accentTeal.opacity(0.7))
                .textCase(.uppercase)

            if isMultiline {
                // TextEditor untuk input multi-baris (Activity, Reward)
                // ZStack digunakan untuk menampilkan placeholder di atas TextEditor
                // karena TextEditor tidak punya placeholder bawaan
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
                // TextField untuk input satu baris (Title, Host)
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

// MARK: - TimePickerSheet (Bottom Sheet Pemilih Waktu)
/// Bottom sheet yang menampilkan time picker dengan interval 15 menit.
/// Dibuka saat user tap baris "Time" di ComposeActivityCard.
struct TimePickerSheet: View {
    /// Waktu yang dipilih — di-bind ke ComposeActivityCard.selectedTime
    @Binding var selectedTime: Date

    /// Warna aksen yang sama dengan ComposeActivityCard
    let accentTeal: Color

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // MARK: Sheet Header
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

            // MARK: Time Picker (UIKit Wrapper dengan Interval 15 Menit)
            // SwiftUI DatePicker tidak support minuteInterval,
            // jadi menggunakan UIKit UIDatePicker yang di-wrap.
            TimePicker15Min(selection: $selectedTime)
                .frame(height: 200)

            Spacer()
        }
    }
}

// MARK: - TimePicker15Min (UIKit Wrapper untuk Time Picker 15 Menit)
/// UIViewRepresentable yang membungkus UIDatePicker dari UIKit.
/// Diperlukan karena SwiftUI DatePicker tidak mendukung minuteInterval (interval menit).
/// Picker ini menampilkan waktu dengan pilihan setiap 15 menit (00, 15, 30, 45).
///
/// Cara kerja UIViewRepresentable:
/// - makeUIView: membuat UIKit view pertama kali
/// - updateUIView: update UIKit view saat data SwiftUI berubah
/// - makeCoordinator: membuat Coordinator yang menjadi penghubung UIKit ↔ SwiftUI
struct TimePicker15Min: UIViewRepresentable {
    /// Waktu yang dipilih — di-bind ke SwiftUI
    @Binding var selection: Date

    /// Membuat UIDatePicker dari UIKit dengan konfigurasi khusus
    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .time             // Hanya tampilkan waktu (tanpa tanggal)
        picker.preferredDatePickerStyle = .wheels  // Style roda putar
        picker.minuteInterval = 15                // Interval 15 menit
        // Hubungkan perubahan nilai picker ke Coordinator
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return picker
    }

    /// Dipanggil saat data SwiftUI berubah — sinkronkan ke UIKit picker
    func updateUIView(_ picker: UIDatePicker, context: Context) {
        picker.date = selection
    }

    /// Buat Coordinator sebagai penghubung UIKit → SwiftUI
    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    /// Coordinator: class yang menangani event dari UIKit dan mengupdate @Binding SwiftUI.
    /// Pola ini diperlukan karena UIKit menggunakan target-action (Objective-C),
    /// sedangkan SwiftUI menggunakan @Binding.
    class Coordinator: NSObject {
        let selection: Binding<Date>
        init(selection: Binding<Date>) { self.selection = selection }

        /// Dipanggil setiap kali user mengubah waktu di picker
        @objc func dateChanged(_ picker: UIDatePicker) {
            selection.wrappedValue = picker.date  // Update SwiftUI @Binding
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ComposeActivityCard(initialTitle: "", initialActivity: "")
    }
}
