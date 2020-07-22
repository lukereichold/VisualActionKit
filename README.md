# VisualActionKit
Human action classification for video, offline and natively on iOS via Core ML

1. For users who don't wish to record video themselves, we can include properly formatted sample videos (at correct frame rate and crop / size).

2. In demo project, have VC that launches rear camera and initiates a recording session. This way we can also control the frame rate (25 fps). Then:
    - Load freshly saved AVAsset
    - **Resize frames to achieve 224x224 resolution**
    - Pass into model for inferencing as in #1...


[ See accompanying blog post ]
