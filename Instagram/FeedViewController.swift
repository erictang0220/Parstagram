//
//  FeedViewController.swift
//  Instagram
//
//  Created by Eric Tang on 3/20/22.
//

import UIKit
import Parse
import AlamofireImage

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var tableView: UITableView!
	var posts = [PFObject]()
	var numPosts = 20
	var refreshControl: UIRefreshControl!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.delegate = self
		tableView.dataSource = self
		
		loadPosts()
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
		tableView.refreshControl = refreshControl
	}
	
	@objc func loadPosts() {
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
	
	// refresh after post a new image
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.loadPosts()
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath.row + 1 == posts.count {
			loadMorePosts()
		}
	}
	
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
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return posts.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
		let post = posts[indexPath.row]
		
		// author is a pointer to a user the User table
		let user = post["author"] as! PFUser
		cell.usernameLabel.text = user.username
		
		cell.captionLabel.text = post["caption"] as! String
		
		let imageFile = post["image"] as! PFFileObject
		let urlString = imageFile.url!
		let url = URL(string: urlString)!
		
		cell.photoView.af.setImage(withURL: url)
		
		return cell
	}
	
}
