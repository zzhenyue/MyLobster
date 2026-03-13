//
//  MyLobsterApp.swift
//  MyLobster
//
//  Created by Yves Chao on 3/10/26.
//

import SwiftUI
import GoogleMobileAds

@main
struct MyLobsterApp: App {

    init() {
        // Don't initialize AdMob in Xcode previews — it crashes the preview process.
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        // Initialize the Google Mobile Ads SDK as early as possible.
        // Ads won't load until this is called.
        MobileAds.shared.start { status in
            print("[AdMob] Init complete. Adapter statuses: \(status.adapterStatusesByClassName.keys.joined(separator: ", "))")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
