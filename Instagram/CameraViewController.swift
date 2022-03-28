//
//  CameraViewController.swift
//  Instagram
//
//  Created by Eric Tang on 3/20/22.
//

import UIKit
import AlamofireImage
import Parse

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
	@IBOutlet weak var imageView: UIImageView!
	
	@IBOutlet weak var commentField: UITextField!
	@IBAction func onSubmitButton(_ sender: Any) {
		let post = PFObject(className: "Posts")
		
		post["caption"] = commentField.text
		post["author"] = PFUser.current()!
		
		let imageData = imageView.image!.pngData()
		// binary object of the image
		// image.png appears on Parse table
		let file = PFFileObject(name: "image.png", data: imageData!)
		
		// contains the URL to the image
		post["image"] = file
		
		post.saveInBackground{(success, error) in
			if success {
				// want to return to the feed view
				self.dismiss(animated: true, completion: nil)
				print("Post picture saved!")
			}
			else {
				print("error saving post picture!")
			}
		}
		
	}
	
	@IBAction func onCameraButton(_ sender: Any) {
		let picker = UIImagePickerController()
		picker.delegate = self
		picker.allowsEditing = true
		
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			picker.sourceType = .camera
		}
		else {
			picker.sourceType = .photoLibrary
		}
		
		present(picker, animated: true, completion: nil)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		let image = info[.editedImage] as! UIImage
		let size = CGSize(width: 300, height: 300)
		let scaledImage = image.af_imageAspectScaled(toFill: size)
		
		imageView.image = scaledImage
		dismiss(animated: true, completion: nil)
		
	}
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
