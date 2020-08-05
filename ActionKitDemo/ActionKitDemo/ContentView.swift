import SwiftUI
import VisualActionKit

struct ContentView: View {
    @State private var showingFilePicker = false
    @State private var videoUrl: URL?
    
    var body: some View {
        
        NavigationView {
            Button(action: {
                showingFilePicker.toggle()
            }) {
                Text("Select Video...")
            }
            .navigationBarTitle("Video Classifier Demo")
            .sheet(isPresented: $showingFilePicker,
                   onDismiss: videoSelected) {
                VideoPicker(videoUrl: self.$videoUrl)
            }
        }
        
        // TODO: add `ProgressView`
        
    }
    
    func videoSelected() {
        guard let inputImage = videoUrl else { return }
        debugPrint(#function)
        debugPrint(inputImage)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
