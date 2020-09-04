//
//  ImageSaver.swift
//  Instafilter
//
//  Created by Xiaolong Zhang on 9/3/20.
//  Copyright © 2020 Xiaolong. All rights reserved.
//

import UIKit

class ImageSaver: NSObject {
    // We need to add "Privacy - Photo Library Additions Usage Description": "Some value" to the Info.plist before attempt to save images to photo library
    var onComplete: ((Result<(), Error>) -> Void)? // Completion handler that contains logic to be called for both success and failure cases
    
    // Method to save photo to album
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }
    
    // Objc method that gets triggered upon image finish saving with either success or error status (and detail)
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            onComplete?(.failure(error))
        } else {
            onComplete?(.success(()))
        }
    }
}
