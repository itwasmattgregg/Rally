import UIKit

/// Keeps the phone process alive long enough after lock / backgrounding to
/// apply WatchConnectivity events and push Bonjour updates to connected iPads.
@MainActor
final class CourtBackgroundHost {
    private var task = UIBackgroundTaskIdentifier.invalid

    /// Call when hosting starts, when entering background, and on each score fan-out.
    func extend(reason: String = "Rally court relay") {
        if task != .invalid {
            // Refresh the existing lease by ending + beginning keeps us in the
            // latest background budget after a WC wake.
            UIApplication.shared.endBackgroundTask(task)
            task = .invalid
        }
        task = UIApplication.shared.beginBackgroundTask(withName: reason) { [weak self] in
            Task { @MainActor [weak self] in
                self?.end()
            }
        }
    }

    func end() {
        guard task != .invalid else { return }
        UIApplication.shared.endBackgroundTask(task)
        task = .invalid
    }
}
