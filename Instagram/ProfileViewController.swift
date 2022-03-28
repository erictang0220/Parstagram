//
//  ProfileViewController.swift
//  Instagram
//
//  Created by Eric Tang on 3/28/22.
//

import UIKit
import AlamofireImage
import Parse

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	var imageSet = false
	@IBOutlet weak var profilePic: UIImageView!
	@IBAction func onSubmitButton(_ sender: Any) {
		
		let user = PFUser.current()!
		let imageData = profilePic.image!.pngData()
		// binary object of the image
		let file = PFFileObject(name: "profilePic.png", data: imageData!)
		
		// contains the URL to the image
		user["profilePic"] = file
		
		user.saveInBackground{(success, error) in
			if success {
				// want to return to the feed view
				self.imageSet = true
				print("Profile picture saved!")
			}
			else {
				print("error saving profile picture!")
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if imageSet {
			self.tabBarController?.selectedIndex = 1
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
		let scaledImage = image.af.imageAspectScaled(toFill: size)
		
		profilePic.image = scaledImage
		dismiss(animated: true, completion: nil)	
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
