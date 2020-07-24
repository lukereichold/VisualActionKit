import XCTest
import AVKit
@testable import VisualActionKit

final class VisualActionKitTests: XCTestCase {
    
    func testClassifyDemoClip() {
        let url = Bundle.module.url(forResource: "writing", withExtension: "mp4")!
        let asset = AVAsset(url: url)
        
        let classification = try! Classifier.shared.classify(asset)
        debugPrint(classification)
    }
    
    func testNormalizedColor() {
        let r = UInt8(40)
        let g = UInt8(60)
        let b = UInt8(165)
        
        let color = NormalizedColor(r, g, b)
        
        XCTAssertEqual(color.red, -0.686, accuracy: 0.001)
        XCTAssertEqual(color.green, -0.529, accuracy: 0.001)
        XCTAssertEqual(color.blue, 0.294, accuracy: 0.001)
    }

    static var allTests = [
        ("testClassifyDemoClip", testClassifyDemoClip),
        ("testNormalizedColor", testNormalizedColor),
    ]
}
