# VisualActionKit

![](https://img.shields.io/badge/Swift-5.3-orange.svg)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/lukereichold/VisualActionKit/blob/master/LICENSE) 
[![SPM compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Twitter](https://img.shields.io/badge/twitter-@lreichold-blue.svg?style=flat)](https://twitter.com/lreichold)

Human action classification for video, offline and natively on iOS via Core ML

Uses the [`kinetics-i3d`]() model to classify videos into one of 400 different action classes defined in [Kinetics 400](https://deepmind.com/research/open-source/kinetics)

⚠️ _This project requires Xcode 12._

**Reference**: [See accompanying blog post](https://lukereichold.com/blog/posts/video-action-classification-coreml/)

## Installation

To install via [Swift Package Manager](https://swift.org/package-manager), add `VisualActionKit` to your `Package.swift` file. Alternatively, add it from Xcode directly.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/lukereichold/VisualActionKit.git", from: "0.1.0")
    ],
    ...
)
```

Then import `VisualActionKit` wherever you’d like to use it:

```swift
import VisualActionKit
```

## Usage

```swift
let url = Bundle.module.url(forResource: "writing", withExtension: "mp4")
let asset = AVAsset(url: url)

let classification = Classifier.shared.classify(asset)
```

## Contribute

Contributions welcome. Please check out [the issues](https://github.com/lukereichold/VisualActionKit/issues).
