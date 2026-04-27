//
//  QuestMail_AppApp.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//
//  File ini adalah entry point (titik awal) aplikasi QuestMail.
//  SwiftUI App lifecycle dimulai dari sini.
//

import SwiftUI

// MARK: - App Entry Point (Titik Masuk Aplikasi)
/// @main menandakan bahwa struct ini adalah entry point aplikasi.
/// Saat app diluncurkan, SwiftUI akan menjalankan struct ini pertama kali.
/// App protocol menggantikan AppDelegate di UIKit — lebih sederhana dan deklaratif.
@main
struct QuestMail_AppApp: App {
    /// body mengembalikan Scene — dalam hal ini WindowGroup yang berisi MainAppView.
    /// WindowGroup: membuat window utama aplikasi dan mengelola lifecycle-nya.
    var body: some Scene {
        WindowGroup {
            // MainAppView adalah root view (view paling atas) dari seluruh aplikasi.
            // Semua navigasi dan tab dimulai dari sini.
            MainAppView()
        }
    }
}
