//
//  ActivityPlanningView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//
//  File ini berisi halaman "Activity Planning" — tempat melihat daftar
//  rencana aktivitas yang sedang diorganisir. User bisa tap salah satu plan
//  untuk mengisi detail dan memindahkannya ke "On Schedule".
//
//  Struktur file:
//  1. ActivityPlanningView — View utama yang menampilkan daftar plans
//  2. ActivityPlanRow      — Komponen baris untuk satu plan
//

import SwiftUI

// MARK: - ActivityPlanningView (View Utama Halaman Activity Planning)
/// Menampilkan daftar rencana aktivitas dalam bentuk list.
/// Saat salah satu plan di-tap, selectedPlan di-set dan MainAppView
/// akan membuka ComposeActivityCard untuk mengisi detail plan tersebut.
struct ActivityPlanningView: View {

    // MARK: - Properties
    /// Daftar rencana aktivitas — read-only (let), data berasal dari MainAppView
    let plans: [ActivityPlan]

    /// Plan yang sedang dipilih — @Binding ke MainAppView.
    /// Saat user tap sebuah plan, value ini di-set → MainAppView mendeteksi perubahan
    /// via .onChange dan membuka ComposeActivityCard dalam mode .editPlan.
    @Binding var selectedPlan: ActivityPlan?

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Section Header
                Text("Being Organized")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // MARK: Plan Rows (Daftar Baris Rencana Aktivitas)
                // Loop setiap plan dan tampilkan sebagai baris yang bisa di-tap.
                // Saat di-tap, selectedPlan diisi → trigger navigasi ke ComposeActivityCard.
                ForEach(plans) { plan in
                    Button {
                        selectedPlan = plan
                    } label: {
                        ActivityPlanRow(plan: plan)
                    }
                    .buttonStyle(.plain)       // Hilangkan style button default (highlight biru)
                    .contentShape(Rectangle())  // Seluruh area baris bisa di-tap (bukan hanya teks)
                    Divider()
                        .padding(.horizontal)
                }

                // MARK: Footer Note (Catatan Informasi di Bawah)
                // Memberitahu user bahwa plan akan pindah ke On Schedule setelah detail lengkap
                Spacer()
                    .frame(height: 60)

                HStack {
                    Spacer()
                    Text("When all details are set,\nevents move to On Schedule")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - ActivityPlanRow (Komponen Baris Satu Plan)
/// View kecil yang menampilkan satu baris rencana aktivitas.
/// Terdiri dari: judul plan, nama organizer, dan chevron (panah kanan).
struct ActivityPlanRow: View {

    /// Data plan yang ditampilkan di baris ini
    let plan: ActivityPlan

    // MARK: - Body
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // MARK: Title (Judul Plan)
                Text(plan.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // MARK: Organizer (Nama Penyelenggara)
                Text("by \(plan.organizer)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // MARK: Chevron (Panah Kanan — Indikasi Bisa Di-tap)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
#Preview {
    ActivityPlanningView(plans: SampleData.activityPlans, selectedPlan: .constant(nil))
}
