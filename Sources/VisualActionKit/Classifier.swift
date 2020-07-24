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
    
    enum ProcessingError: Error {
        case unsupportedFrameCount
        case videoFrameIsTooSmall
        case resizingFailure
    }
    
    func classify(_ asset: AVAsset, then completion: (Predictions) -> Void) throws {
        
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
            
            guard var imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
            imageBuffer = try resizeIfNecessary(buffer: imageBuffer)
            
            extractRgbValuesInCenterCrop(from: imageBuffer, to: &multi, for: currentFrame)
            currentFrame += 1
        }
        
        completion(try performInference(for: multi))
    }
}

private extension Classifier {
    
    /// Resize a frame preserving its aspect ratio such that the smallest dimension is 256 pixels.
    func resizeIfNecessary(buffer: CVPixelBuffer) throws -> CVPixelBuffer {
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let shorterDimension = min(width, height)
        
        guard shorterDimension >= 224 else { throw ProcessingError.videoFrameIsTooSmall }
        guard shorterDimension >= 256 else { return buffer }
        
        /// Aspect ratio is preserved since both width and height dimensions are scaled down by same factor.
        /// As a result, either new height or new width will be 256.
        let scale = 256.0 / Double(shorterDimension)
        guard let resizedBuffer = resizePixelBuffer(buffer,
                                                    width: Int(scale * Double(width)),
                                                    height: Int(scale * Double(height))) else {
            throw ProcessingError.resizingFailure
        }
        return resizedBuffer
    }
    
    func performInference(for tensor: MultiArray<Float32>) throws -> Predictions {
        let input = KineticsInput(Placeholder: tensor.array)
        let output = try model.prediction(input: input)
        return top(5, output.Softmax)
    }
    
    func extractRgbValuesInCenterCrop(from buffer: CVPixelBuffer,
                                      to tensor: inout MultiArray<Float32>,
                                      for frameIndex: Int) {
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        
        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(buffer, flags) else { return }
        guard let baseAddr = CVPixelBufferGetBaseAddress(buffer) else { return }
        let pixels = baseAddr.assumingMemoryBound(to: UInt8.self)
        
        let cropOriginX = width / 2 - frameSize / 2
        let cropOriginY = height / 2 - frameSize / 2
        
        for x in 0 ..< frameSize {
            for y in 0 ..< frameSize {
                let relativeX = cropOriginX + x
                let relativeY = cropOriginY + y
                
                let index = relativeX * 4 + relativeY * bytesPerRow
                let b = pixels[index]
                let g = pixels[index+1]
                let r = pixels[index+2]
                
                let color = NormalizedColor(r, g, b)
                
                tensor[0, frameIndex, x, y, 0] = color.red
                tensor[0, frameIndex, x, y, 1] = color.green
                tensor[0, frameIndex, x, y, 2] = color.blue
            }
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, flags)
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
struct NormalizedColor: CustomStringConvertible {
    let red: Float32
    let green: Float32
    let blue: Float32
    
    init(_ r: UInt8, _ g: UInt8, _ b: UInt8) {
        red = Float32(2 * (Double(r) / 255.0) - 1)
        green = Float32(2 * (Double(g) / 255.0) - 1)
        blue = Float32(2 * (Double(b) / 255.0) - 1)
    }
    
    var description: String {
        "(\(red), \(green), \(blue))"
    }
}
