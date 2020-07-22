import Foundation
import AVKit
import CoreML

public class Classifier {
    static let shared = Classifier()
    let frameSize = 224
    let model: Kinetics
    
    private init() {
        let modelUrl = Bundle.module.url(forResource: "Kinetics", withExtension: "mlmodel")!
        let compiledModelURL = try! MLModel.compileModel(at: modelUrl)
        let mlModel = try! MLModel(contentsOf: compiledModelURL)
        model = Kinetics(model: mlModel)
    }
    
    public func classify(_ asset: AVAsset) {
        
        let reader = try! AVAssetReader(asset: asset)
        let videoTrack = asset.tracks(withMediaType: .video)[0]
            
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])

        reader.add(trackReaderOutput)
        reader.startReading()
        
        var multi = MultiArray<Float32>(shape: [1, asset.frameCount(), frameSize, frameSize, 3])
        
        var currentFrame = 0
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                
                CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
                
                let width = CVPixelBufferGetWidth(imageBuffer)
                let height = CVPixelBufferGetHeight(imageBuffer)
                let shorterDimension = min(width, height)
                
                guard shorterDimension >= 256 else { continue }
                
                let scale = 256.0 / Double(shorterDimension)
                let newWidth = Int(scale * Double(width))
                let newHeight = Int(scale * Double(height))
                
                /// Aspect ratio is preserved since both width and height dimensions are scaled down by same factor.
                /// Now, either `newHeight` or `newWidth` will be 256.
                guard let resizedBuffer = resizePixelBuffer(imageBuffer, width: newWidth, height: newHeight) else {
                    continue
                }
                
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
                        
                        let color = NormalizedColor(r, g, b)

                        multi[0, currentFrame, x, y, 0] = color.red
                        multi[0, currentFrame, x, y, 1] = color.green
                        multi[0, currentFrame, x, y, 2] = color.blue
                    }
                }
                
                CVPixelBufferUnlockBaseAddress(resizedBuffer, CVPixelBufferLockFlags(rawValue: 0))
                CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            }
            currentFrame += 1
        }
        
        let input = KineticsInput(Placeholder: multi.array)
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


struct NormalizedColor {
    let red: Float32
    let green: Float32
    let blue: Float32
    
    init(_ r: UInt8, _ g: UInt8, _ b: UInt8) {
        red = Float32(2 * (Double(r) / 255.0) - 1)
        green = Float32(2 * (Double(g) / 255.0) - 1)
        blue = Float32(2 * (Double(b) / 255.0) - 1)
    }
}
