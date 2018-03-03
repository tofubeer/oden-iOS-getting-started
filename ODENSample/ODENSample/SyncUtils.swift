import Foundation

// https://stackoverflow.com/questions/24045895/what-is-the-swift-equivalent-to-objective-cs-synchronized
func sync(_ lock: Any!, closure: () -> Void)
{
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}
