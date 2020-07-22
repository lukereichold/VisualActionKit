import XCTest
import AVKit
@testable import VisualActionKit

final class VisualActionKitTests: XCTestCase {
    
    func testClassifyDemoClip() {
        let url = Bundle.module.url(forResource: "writing", withExtension: "mp4")!
        let asset = AVAsset(url: url)
        
        let classification = Classifier.shared.classify(asset)
    }

    static var allTests = [
        ("testClassifyDemoClip", testClassifyDemoClip),
    ]
}
