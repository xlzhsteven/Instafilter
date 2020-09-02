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
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    @State var currentFilter = CIFilter.sepiaTone()
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
                    Button("Change Filter") {
                        // change filter
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        // save the picture
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
            .sheet(isPresented: $showingImagePicker,
                   onDismiss: loadImage) { // When sheet is dismissed, call loadImage()
                ImagePicker(image: self.$inputImage) // Present ImagePicker in a sheet
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
        currentFilter.intensity = Float(filterIntensity) // Set filter intensity with filterIntensity value
        
        guard let outputImage = currentFilter.outputImage else { return } // Get output input with CIImage type
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) { // Create CGImage fro CIImage
            let uiImage = UIImage(cgImage: cgimg) // Create UIImage from CIImage
            image = Image(uiImage: uiImage) // Save the transformed image to the image placeholder
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
