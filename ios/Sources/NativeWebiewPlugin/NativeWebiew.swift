import Foundation

@objc public class NativeWebiew: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
