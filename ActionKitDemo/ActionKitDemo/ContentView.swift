import SwiftUI
import VisualActionKit
import AVKit

struct Results: Identifiable {
    let id = UUID()
    let text: String
}

struct ContentView: View {
    @State private var showingFilePicker = false
    @State private var showSpinner = false
    @State private var videoUrl: URL?
    @State private var results: Results?
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    showingFilePicker.toggle()
                }) {
                    Text("Select video...")
                }
                .padding(.bottom, 100)
                .alert(item: $results) { message in
                    Alert(
                        title: Text(results?.text ?? ""),
                        dismissButton: .default(Text("Dismiss"))
                    )
                }
                
                if $showSpinner.wrappedValue {
                    ProgressView("Classifying video...")
                }
            }
            
            .navigationBarTitle("Video Classifier Demo")
            .sheet(isPresented: $showingFilePicker,
                   onDismiss: videoSelected) {
                VideoPicker(videoUrl: self.$videoUrl)
            }
        }
    }
    
    func videoSelected() {
        guard let url = videoUrl else { return }
        let asset = AVAsset(url: url)
        
        showSpinner.toggle()
        defer { showSpinner.toggle() }
        
        DispatchQueue.global(qos: .default).async {
            do {
                try Classifier.shared.classify(asset) { predictions in
                    results = Results(text: predictions.description)
                }
            } catch {
                debugPrint(error)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
