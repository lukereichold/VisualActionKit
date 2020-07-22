import CoreML

@available(macOS 10.16, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
class KineticsInput : MLFeatureProvider {
    var Placeholder: MLMultiArray

    var featureNames: Set<String> {
        get {
            return ["Placeholder"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "Placeholder") {
            return MLFeatureValue(multiArray: Placeholder)
        }
        return nil
    }
    
    init(Placeholder: MLMultiArray) {
        self.Placeholder = Placeholder
    }
}

@available(macOS 10.16, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
class KineticsOutput : MLFeatureProvider {

    private let provider : MLFeatureProvider

    lazy var Softmax: [String : Double] = {
        [unowned self] in return self.provider.featureValue(for: "Softmax")!.dictionaryValue as! [String : Double]
    }()
    lazy var classLabel: String = {
        [unowned self] in return self.provider.featureValue(for: "classLabel")!.stringValue
    }()

    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    init(Softmax: [String : Double], classLabel: String) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["Softmax" : MLFeatureValue(dictionary: Softmax as [AnyHashable : NSNumber]), "classLabel" : MLFeatureValue(string: classLabel)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}

@available(macOS 10.16, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
class Kinetics {
    let model: MLModel
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "Kinetics", withExtension:"mlmodelc")!
    }
    init(model: MLModel) {
        self.model = model
    }
    @available(*, deprecated, message: "Use init(configuration:) instead and handle errors appropriately.")
    convenience init() {
        try! self.init(contentsOf: type(of:self).urlOfModelInThisBundle)
    }
    convenience init(configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Result<Kinetics, Error>) -> Void) {
        return self.load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Result<Kinetics, Error>) -> Void) {
        MLModel.__loadContents(of: modelURL, configuration: configuration) { (model, error) in
            if let error = error {
                handler(.failure(error))
            } else if let model = model {
                handler(.success(Kinetics(model: model)))
            } else {
                fatalError("SPI failure: -[MLModel loadContentsOfURL:configuration::completionHandler:] vends nil for both model and error.")
            }
        }
    }
    func prediction(input: KineticsInput) throws -> KineticsOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }
    func prediction(input: KineticsInput, options: MLPredictionOptions) throws -> KineticsOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return KineticsOutput(features: outFeatures)
    }
    func prediction(Placeholder: MLMultiArray) throws -> KineticsOutput {
        let input_ = KineticsInput(Placeholder: Placeholder)
        return try self.prediction(input: input_)
    }
    func predictions(inputs: [KineticsInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [KineticsOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [KineticsOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  KineticsOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
