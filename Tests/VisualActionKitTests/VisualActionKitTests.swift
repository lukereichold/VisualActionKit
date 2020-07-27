import XCTest
import AVKit
@testable import VisualActionKit

final class VisualActionKitTests: XCTestCase {
    
    enum TestClip: String {
        case writing
        case cricketShot
        case makingTea = "making tea"
        case readingBook = "reading book"
        case stretchingArm = "stretching arm"
        case rockPaperScissors = "rock scissors paper"
        
        var path: URL {
            Bundle.module.url(forResource: rawValue, withExtension: "mp4")!
        }
    }
    
    func testClassifyDemoClip() {
        let asset = AVAsset(url: TestClip.cricketShot.path)
        
        let expectation = self.expectation(description: TestClip.cricketShot.rawValue)
        var actualPredictions: Classifier.Predictions?
        
        try! Classifier.shared.classify(asset) { predictions in
            actualPredictions = predictions
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertEqual(actualPredictions?.first?.classLabel, "playing cricket")
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
