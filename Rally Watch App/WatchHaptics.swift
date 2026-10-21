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

    static func matchStart() {
        WKInterfaceDevice.current().play(.start)
    }

    static func matchStop() {
        WKInterfaceDevice.current().play(.stop)
    }
}
