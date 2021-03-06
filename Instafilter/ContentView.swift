//
//  ContentView.swift
//  Instafilter
//
//  Created by Xiaolong Zhang on 8/27/20.
//  Copyright © 2020 Xiaolong. All rights reserved.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ContentView: View {
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var showingFilterSheet = false
    
    @State private var showNoImageAlert = false
    @State private var changeFilterButtonText = "Change Filter"
    @State var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var body: some View {
        // Create Binding that returns filterIntensity when fetching
        // When setting the value, update filterIntensity and also trigger applyProcessing() method
        // This is needed since @State is struct, wrappedValue is nonmutating, we have to create a custom binding to provide our own code to run when the value is read or written
        // https://www.hackingwithswift.com/books/ios-swiftui/creating-custom-bindings-in-swiftui for more details
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        
        let radius = Binding<Double>(
            get: {
                self.filterRadius
            },
            set: {
                self.filterRadius = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)
                    
                    if image != nil {
                        image?.resizable().scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker = true // Tap to show image picker
                }
                
                HStack {
                    Text("Intensity")
                    Slider(value: intensity)
                }
                .padding(.vertical)
                
                HStack {
                    Text("Radius")
                    Slider(value: radius)
                }
                .padding(.vertical)
                
                HStack {
                    Button(changeFilterButtonText) {
                        self.showingFilterSheet = true
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        // Unwrap processedImage
                        guard let processedImage = self.processedImage else {
                            self.showNoImageAlert = true
                            return
                        }
                        
                        // Initialize image saver
                        let imageSaver = ImageSaver()
                        // Provide success/failure handler to the image saver
                        imageSaver.onComplete = { result in
                            switch result {
                            case .failure(_):
                                print("Save failed")
                            case .success(_):
                                print("Save successful")
                            }
                        }
                        // Trigger image saving
                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
            .sheet(isPresented: $showingImagePicker,
                   onDismiss: loadImage) { // When sheet is dismissed, call loadImage()
                ImagePicker(image: self.$inputImage) // Present ImagePicker in a sheet
            }
            .actionSheet(isPresented: $showingFilterSheet) { () -> ActionSheet in
                // Create ActionSheet with buttons to apply different filters
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Crystallize")) { self.setFilter(CIFilter.crystallize()); self.changeFilterButtonText = "Crystallize" },
                    .default(Text("Edges")) { self.setFilter(CIFilter.edges()); self.changeFilterButtonText = "Edges" },
                    .default(Text("Gaussian Blur")) { self.setFilter(CIFilter.gaussianBlur()); self.changeFilterButtonText = "Gaussian Blur" },
                    .default(Text("Pixellate")) { self.setFilter(CIFilter.pixellate()); self.changeFilterButtonText = "Pixellate" },
                    .default(Text("Sepia Tone")) { self.setFilter(CIFilter.sepiaTone()); self.changeFilterButtonText = "Sepia Tone" },
                    .default(Text("Unsharp Mask")) { self.setFilter(CIFilter.unsharpMask()); self.changeFilterButtonText = "Unsharp Mask" },
                    .default(Text("Vignette")) { self.setFilter(CIFilter.vignette()); self.changeFilterButtonText = "Vignette" },
                    .cancel()
                ])
            }
            .alert(isPresented: $showNoImageAlert) { () -> Alert in
                Alert(title: Text("No image selected"), message: nil, dismissButton: .cancel())
            }
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        let beginImage = CIImage(image: inputImage) // Create CIImage from UIImage
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey) // Set input image to the filter
        applyProcessing() // Process image
    }
    
    func applyProcessing() {
        // Apply slider value differently for different type of filter input keys (Prevent crash due to different values are needed for different keys as well)
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) }
        
        guard let outputImage = currentFilter.outputImage else { return } // Get output input with CIImage type
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) { // Create CGImage fro CIImage
            let uiImage = UIImage(cgImage: cgimg) // Create UIImage from CIImage
            image = Image(uiImage: uiImage) // Save the transformed image to the image placeholder
            processedImage = uiImage // Save the processed image so it can be used later
        }
    }
    
    // Set currentFilter with filter from the method argument, then load image
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
