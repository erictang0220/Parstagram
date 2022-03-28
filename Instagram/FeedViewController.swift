//
//  FeedViewController.swift
//  Instagram
//
//  Created by Eric Tang on 3/20/22.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
	
	@IBAction func onLogoutButton(_ sender: Any) {
		PFUser.logOut()
		let main = UIStoryboard(name: "Main", bundle: nil)
		let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
		// get window from sceneDelegate
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else {return}
		delegate.window?.rootViewController = loginViewController
	}
	
	@IBOutlet weak var tableView: UITableView!
	let commentBar = MessageInputBar()
	var showsCommentBar = false
	var posts = [PFObject]()
	var numPosts = 20
	var selectedPost: PFObject!
	var refreshControl: UIRefreshControl!
	
	override var inputAccessoryView: UIView? {
		return commentBar
	}
	
	override var canBecomeFirstResponder: Bool {
		return showsCommentBar
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		commentBar.inputTextView.placeholder = "Add a comment..."
		commentBar.sendButton.title = "Post"
		commentBar.delegate = self
		
		tableView.delegate = self
		tableView.dataSource = self
		tableView.keyboardDismissMode = .interactive
		let center = NotificationCenter.default
		// when keyboard is hiding, call keyboardWillBeHidden to hide the comment bar
		center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		
		loadPosts()
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
		tableView.refreshControl = refreshControl
	}
	
	@objc func keyboardWillBeHidden(note: Notification) {
		commentBar.inputTextView.text = nil
		showsCommentBar = false
		becomeFirstResponder()
	}
	
	func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
		// Create the comment
		let comment = PFObject(className: "Comments")
		comment["text"] = text
		comment["post"] = selectedPost
		comment["author"] = PFUser.current()!
		
		// .add is for array!!!
		selectedPost.add(comment, forKey: "comments")
		
		selectedPost.saveInBackground{(success, error) in
			if success {
				print("Comment saved")
			}
			else {
				print("Error saving comment")
			}
		}
		tableView.reloadData()
		
		// clear and dismiss input bar
		commentBar.inputTextView.text = nil
		showsCommentBar = false
		becomeFirstResponder()
		commentBar.inputTextView.resignFirstResponder()
	}
	
	@objc func loadPosts() {
		let query = PFQuery(className: "Posts")
		// include items we want to fetch
		// comments.author --> two indirections
		query.includeKeys(["author", "comments", "comments.author"])
		query.limit = numPosts
		query.findObjectsInBackground {(fetchedPosts, error) in
			if fetchedPosts != nil {
				self.posts = fetchedPosts!.reversed()
				self.tableView.reloadData()
				self.refreshControl.endRefreshing()
			}
			else {
				print("Error: \(error)")
			}
		}
	}
	
	// refresh after post a new image
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.loadPosts()
	}
	
//	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//		if indexPath.section + 1 == posts.count {
//			loadMorePosts()
//		}
//	}
	
	func loadMorePosts() {
		numPosts = numPosts + 20
		let query = PFQuery(className: "Posts")
		// include author so know which pointer to fetch
		query.includeKey("author")
		query.limit = numPosts
		query.findObjectsInBackground {(fetchedPosts, error) in
			if fetchedPosts != nil {
				self.posts = fetchedPosts!.reversed()
				self.tableView.reloadData()
				self.refreshControl.endRefreshing()
			}
			else {
				print("Error: \(error)")
			}
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let post = posts[indexPath.section]
		let comments = (post["comments"] as? [PFObject]) ?? []
		
		if indexPath.row == comments.count + 1 {
			showsCommentBar = true
			// update value by calling the function
			becomeFirstResponder()
			// raise the keyboard
			commentBar.inputTextView.becomeFirstResponder()
			// if scroll down later, still remember the post selected
			selectedPost = post
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let post = posts[section]
		// if stuff in () is nil replace it with stuff in []
		let comments = (post["comments"] as? [PFObject]) ?? []
		// number of comments + one post + one "Add a comment..."
		return comments.count + 2
	}
	
	// each post is represented by a section
	// a section can have multiple rows (each comment is a row)
	func numberOfSections(in tableView: UITableView) -> Int {
		return posts.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let post = posts[indexPath.section]
		let comments = (post["comments"] as? [PFObject]) ?? []
		
		// the first element is the post cell
		if indexPath.row == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
			
			
			// author is a pointer to a user the User table
			let user = post["author"] as! PFUser
			cell.usernameLabel.text = user.username
			
			cell.captionLabel.text = post["caption"] as! String
			
			let imageFile = post["image"] as! PFFileObject
			let urlString = imageFile.url!
			let url = URL(string: urlString)!
			
			cell.photoView.af.setImage(withURL: url)
			
			let profilePicFile = user["profilePic"]
			if profilePicFile != nil {
				let validProfile = profilePicFile as! PFFileObject
				let profileUrlString = validProfile.url!
				let profileUrl = URL(string: profileUrlString)!
				cell.profilePicView.af.setImage(withURL: profileUrl)
			}
			else {
				cell.profilePicView.image = UIImage(named: "image_placeholder")
			}

			return cell
		}
		// else if a comment cell
		else if indexPath.row <= comments.count {
			let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
			
			// -1 because the first one is for post cell!!
			let comment = comments[indexPath.row - 1]
			cell.commentLabel.text = comment["text"] as? String
			
			let user = comment["author"] as! PFUser
			cell.nameLabel.text = user.username
			
			var profilePicFile = user["profilePic"]
			if profilePicFile != nil {
				let validProfile = profilePicFile as! PFFileObject
				let profileUrlString = validProfile.url!
				let profileUrl = URL(string: profileUrlString)!
				cell.profilePicView.af.setImage(withURL: profileUrl)
			}
			else {
				cell.profilePicView.image = UIImage(named: "image_placeholder")
			}
			
			return cell
		}
		else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
			return cell
		}
		
		
	}
	
}
