# VisualActionKit

![](https://img.shields.io/badge/Swift-5.3-orange.svg)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/lukereichold/VisualActionKit/blob/master/LICENSE) 
[![SPM compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
    
Human action classification for video, offline and natively on iOS via Core ML


## Installation

Ink is distributed using the [Swift Package Manager](https://swift.org/package-manager). To install it into a project, simply add it as a dependency within your `Package.swift` manifest:

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/lukereichold/VisualActionKit.git", from: "0.1.0")
    ],
    ...
)
```

Then import VisualActionKit wherever you’d like to use it:

```swift
import VisualActionKit
```

[ See accompanying blog post ]


## Usage

```swift
let url = Bundle.module.url(forResource: "writing", withExtension: "mp4")
let asset = AVAsset(url: url)

let classification = Classifier.shared.classify(asset)
```

## Contribute

Contributions welcome. Please check out [the issues](https://github.com/lukereichold/VisualActionKit/issues).
