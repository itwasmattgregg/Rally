import WatchKit

enum WatchHaptics {
    static func scoreUp() {
        WKInterfaceDevice.current().play(.directionUp)
    }

    static func scoreDown() {
        WKInterfaceDevice.current().play(.directionDown)
    }

    static func reset() {
        WKInterfaceDevice.current().play(.success)
    }
}
