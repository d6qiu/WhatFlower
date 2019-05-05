//
//  ViewController.swift
//  WhatFlower
//
//  Created by wenlong qiu on 7/17/18.
//  Copyright © 2018 wenlong qiu. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
//13
import SDWebImage

//1
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //2
    let imagePicker = UIImagePickerController()
    //9
    let wikipediaURL = "https://en.wikipedia.org/w/api.php?"
    @IBOutlet weak var imageView: UIImageView!
    //12
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //3
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }

    //4
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let userPickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            //7 coreml image object
            guard let convertedCIImage = CIImage(image: userPickedImage) else { fatalError("cannot convert to ciimage")}
            
            detect(image: convertedCIImage)
            //iamgeView.image = userPickedImage
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    //6
    func detect(image: CIImage) {
        //8 vision model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {fatalError("cannot import model")}
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            //guard and if let determines what to do if nil
            guard let classification = request.results?.first as? VNClassificationObservation else {fatalError("could not classify image")}
            self.navigationItem.title = classification.identifier.capitalized  //name of object identified, make image to aspect fill in mainstory board, only capitalized the first letter
            //11
            self.requestInfo(flowerName: classification.identifier)
            
        }
        //handler that performs requests
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    //10
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = ["format" : "json", "action" : "query", "prop" : "extracts|pageimages", "exintro" : "", "explaintext" : "", "titles" : flowerName, "indexpageids" : "", "redirects" : "1", "pithumbsize" : "500"]
        //.responsseJSON adds a handler to be called once the request has finished.
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in //this response object is not json
            if response.result.isSuccess {
                print("got data")
                let flowerJSON : JSON = JSON(response.result.value!) //since result is succes, safe to force unwrap
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                //14
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL)) //calls url constructor
                self.label.text = flowerDescription
            }
        }
    }
    
    //5
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    

}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
