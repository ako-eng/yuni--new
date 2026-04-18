import CoreMotion
import Foundation
import Observation

/// Drives subtle parallax for onboarding bubbles from device attitude (roll / pitch).
@Observable
final class DeviceParallaxController {
    /// Normalized tilt factors roughly in [-0.5, 0.5] for mapping to screen offset in the view layer.
    var tiltX: CGFloat = 0
    var tiltY: CGFloat = 0

    private let motion = CMMotionManager()

    func start(reduceMotion: Bool) {
        stop()
        guard !reduceMotion, motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 45.0
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, _ in
            guard let self, let att = data?.attitude else { return }
            let roll = CGFloat(att.roll)
            let pitch = CGFloat(att.pitch)
            self.tiltX = max(-0.55, min(0.55, roll / 1.15))
            self.tiltY = max(-0.55, min(0.55, -pitch / 1.15))
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        tiltX = 0
        tiltY = 0
    }
}
