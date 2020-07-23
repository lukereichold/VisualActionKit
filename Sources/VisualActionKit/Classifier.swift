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
}

public extension Classifier {
    
    typealias Predictions = [(classLabel: String, probability: Double)]
    
    struct VideoMetadata {
        var width: Int
        var height: Int
        var frame: Int
    }
    
    enum ProcessingError: Error {
        case unsupportedFrameCount
        case videoFrameIsTooSmall
    }
    
    func classify(_ asset: AVAsset) throws -> Predictions {
        
        let reader = try AVAssetReader(asset: asset)
        let videoTrack = asset.tracks(withMediaType: .video)[0]
        
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
        let frameCount = asset.frameCount()
        
        guard 25...300 ~= frameCount else {
            throw ProcessingError.unsupportedFrameCount
        }
        
        reader.add(trackReaderOutput)
        reader.startReading()
        
        /// 5D tensor containing RGB data for each pixel in each sequntial frame of the video.
        var multi = MultiArray<Float32>(shape: [1, frameCount, frameSize, frameSize, 3])
        
        var currentFrame = 0
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
            
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
            CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            var width = CVPixelBufferGetWidth(imageBuffer)
            var height = CVPixelBufferGetHeight(imageBuffer)
            let shorterDimension = min(width, height)
            
            guard shorterDimension >= 224 else { throw ProcessingError.videoFrameIsTooSmall }
            
            var resizedBuffer: CVPixelBuffer
            if shorterDimension >= 256 {
                
                let scale = 256.0 / Double(shorterDimension)
                width = Int(scale * Double(width))
                height = Int(scale * Double(height))
                
                /// Aspect ratio is preserved since both width and height dimensions are scaled down by same factor.
                /// Now, either `newHeight` or `newWidth` will be 256.
                 resizedBuffer = resizePixelBuffer(imageBuffer, width: width, height: height)
            }
            
            CVPixelBufferLockBaseAddress(resizedBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            let metadata = VideoMetadata(width: width, height: height, frame: frameCount)
            extractRgbValuesInCenterCrop(for: resizedBuffer, to: &multi, with: metadata)
            
            CVPixelBufferUnlockBaseAddress(resizedBuffer, CVPixelBufferLockFlags(rawValue: 0))
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            currentFrame += 1
        }
        
        return try performInference(for: multi)
    }
}

private extension Classifier {
        
    func performInference(for tensor: MultiArray<Float32>) throws -> Predictions {
        let input = KineticsInput(Placeholder: tensor.array)
        let output = try model.prediction(input: input)
        return top(5, output.Softmax)
    }
    
    func extractRgbValuesInCenterCrop(for buffer: CVPixelBuffer,
                                      to tensor: inout MultiArray<Float32>,
                                      with metadata: VideoMetadata) {
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        guard let baseAddr = CVPixelBufferGetBaseAddress(buffer) else { return }
        let buffer = baseAddr.assumingMemoryBound(to: UInt8.self)
        
        let cropOriginX = metadata.width / 2 - frameSize / 2
        let cropOriginY = metadata.height / 2 - frameSize / 2
        
        for x in 0 ..< frameSize {
            for y in 0 ..< frameSize {
                let relativeX = cropOriginX + x
                let relativeY = cropOriginY + y
                
                let index = relativeX * 4 + relativeY * bytesPerRow
                let b = buffer[index]
                let g = buffer[index+1]
                let r = buffer[index+2]
                
                let color = NormalizedColor(r, g, b)
                
                tensor[0, metadata.frame, x, y, 0] = color.red
                tensor[0, metadata.frame, x, y, 1] = color.green
                tensor[0, metadata.frame, x, y, 2] = color.blue
            }
        }
    }
    
    /// Resize a frame preserving its aspect ratio such that the smallest dimension is 256 pixels.
    func resize(buffer: CVPixelBuffer) -> CVPixelBuffer? {

        // coming soon?
        return nil
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

/// Color with RGB values that are rescaled between -1 and 1.
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
