//
//  AdManager.swift
//  MyLobster
//
//  Manages AdMob interstitial ads.
//  Uses TEST unit IDs — swap for real IDs before App Store submission.
//
//  TEST IDs (Google official):
//    App ID:       ca-app-pub-3940256099942544~1458002511   (Info.plist)
//    Interstitial: ca-app-pub-3940256099942544/4411468910
//

import GoogleMobileAds
import UIKit

// MARK: - Ad unit ID

private enum AdUnitID {
    /// Replace with your real interstitial unit ID before shipping.
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
}

// MARK: - AdManager

final class AdManager: NSObject {

    // MARK: - Frequency

    /// Runs needed before the next ad. Re-randomised in [3, 5] after each ad shows.
    private var runsUntilNextAd: Int
    private var runsSinceLastAd = 0

    // MARK: - Private

    private var interstitial: InterstitialAd?
    private var pendingCompletion: (() -> Void)?

    // MARK: - Init

    override init() {
        runsUntilNextAd = Int.random(in: 3...5)
        super.init()
        // Don't touch AdMob in Xcode previews — it crashes the preview process.
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        loadInterstitial()
    }

    // MARK: - Load

    private func loadInterstitial() {
        InterstitialAd.load(
            with: AdUnitID.interstitial,
            request: Request(),
            completionHandler: { [weak self] ad, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let error {
                        print("[AdManager] Load failed: \(error.localizedDescription)")
                        // Retry after 5 s to avoid hammering the network
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            self.loadInterstitial()
                        }
                        return
                    }
                    self.interstitial = ad
                    self.interstitial?.fullScreenContentDelegate = self
                    print("[AdManager] Interstitial ready.")
                }
            }
        )
    }

    // MARK: - Show

    /// Call after each game ends. Shows an interstitial every `showEvery` runs.
    /// Always calls `completion` — either after the ad is dismissed, or immediately if no ad fires.
    func onGameFinished(from rootVC: UIViewController, completion: @escaping () -> Void) {
        runsSinceLastAd += 1
        guard runsSinceLastAd >= runsUntilNextAd, let ad = interstitial else {
            // Not yet time, or no ad loaded — go straight to result
            completion()
            return
        }
        // Reset counter, pick a new random threshold, then present
        runsSinceLastAd = 0
        runsUntilNextAd = Int.random(in: 3...5)
        pendingCompletion = completion
        ad.present(from: rootVC)
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        let completion = pendingCompletion
        pendingCompletion = nil
        loadInterstitial()   // pre-load the next one
        completion?()
    }

    func ad(_ ad: any FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdManager] Present failed: \(error.localizedDescription)")
        let completion = pendingCompletion
        pendingCompletion = nil
        loadInterstitial()
        completion?()
    }
}
