import UIKit
import AVKit
import CoreML

class ViewController: UIViewController {

    let frameSize = 224
    var model: Kinetics1!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model = Kinetics1()
        
        let url = Bundle.main.url(forResource: "stretching_arm", withExtension: "mp4")!
        let asset = AVAsset(url: url)

        let reader = try! AVAssetReader(asset: asset)
        let videoTrack = asset.tracks(withMediaType: .video)[0]

        debugPrint("Frame rate: ", videoTrack.nominalFrameRate)
        
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])

        reader.add(trackReaderOutput)
        reader.startReading()
        
        var multi = MultiArray<Float32>(shape: [1, asset.frameCount(), frameSize, frameSize, 3])
        
        var currentFrame = 0
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
//            print("sample at time \(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))")
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                
                CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
                
                let width = CVPixelBufferGetWidth(imageBuffer)
                let height = CVPixelBufferGetHeight(imageBuffer)
                let shorterDimension = min(width, height)
                
                guard shorterDimension >= 256 else { continue }
                
                let scale = 256.0 / Double(shorterDimension)
                let newWidth = Int(scale * Double(width))
                let newHeight = Int(scale * Double(height))
                
//                debugPrint(newWidth)
//                debugPrint(newHeight)
                
//                let start = CFAbsoluteTimeGetCurrent()
            
                /// Aspect ratio is preserved since both width and height dimensions are scaled down by same factor.
                /// Now, either `newHeight` or `newWidth` will be 256.
                guard let resizedBuffer = resizePixelBuffer(imageBuffer, width: newWidth, height: newHeight) else {
                    continue
                }
                
                // run your work
//                let diff = CFAbsoluteTimeGetCurrent() - start
//                print("Took \(diff) seconds")
                
                // cool, this works, just for testing:
                assert(CVPixelBufferGetWidth(resizedBuffer) == newWidth)
                assert(CVPixelBufferGetHeight(resizedBuffer) == newHeight)
                
                CVPixelBufferLockBaseAddress(resizedBuffer, CVPixelBufferLockFlags(rawValue: 0))
                let bytesPerRow = CVPixelBufferGetBytesPerRow(resizedBuffer)
                guard let baseAddr = CVPixelBufferGetBaseAddress(resizedBuffer) else { continue }
                let buffer = baseAddr.assumingMemoryBound(to: UInt8.self)

                /// After resizing, we focus on only the center 224 x 224 rect of the frame.
                let cropOriginX = newWidth / 2 - frameSize / 2
                let cropOriginY = newHeight / 2 - frameSize / 2
                
                for x in 0 ..< frameSize {
                    for y in 0 ..< frameSize {
                        let relativeX = cropOriginX + x
                        let relativeY = cropOriginY + y

                        let index = relativeX * 4 + relativeY * bytesPerRow
                        let b = buffer[index]
                        let g = buffer[index+1]
                        let r = buffer[index+2]
//                        print(r,g,b)
                        
                        let red = Float32(2 * (Double(r) / 255.0) - 1)
                        let green = Float32(2 * (Double(g) / 255.0) - 1)
                        let blue = Float32(2 * (Double(b) / 255.0) - 1)
                        
                        multi[0, currentFrame, x, y, 0] = red
                        multi[0, currentFrame, x, y, 1] = green
                        multi[0, currentFrame, x, y, 2] = blue
                    }
                }
                
                CVPixelBufferUnlockBaseAddress(resizedBuffer, CVPixelBufferLockFlags(rawValue: 0))
                CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            }
            currentFrame += 1
        }
        
        let input = Kinetics1Input(Placeholder: multi.array)
        if let output = try? model.prediction(input: input) {
            debugPrint(top(5, output.Softmax))
            debugPrint(output.classLabel)
        }
        
    }

}

extension AVAsset {
    func frameCount() -> Int {
        let reader = try! AVAssetReader(asset: self)
        let videoTrack = tracks(withMediaType: .video)[0]
        
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])

        reader.add(trackReaderOutput)
        reader.startReading()
        
        var frameCount = 0
        while let _ = trackReaderOutput.copyNextSampleBuffer() {
            frameCount += 1
        }
        return frameCount
    }
}
