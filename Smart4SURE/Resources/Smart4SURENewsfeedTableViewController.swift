//
//  Smart4SURENewsfeedTableViewController.swift
//  Smart4SURE
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import BridgeAppSDK

class Smart4SURENewsfeedTableViewController: UITableViewController {
    
    static let tabItemTag = 4
    
    var newsfeedManager: SBANewsFeedManager {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.newsfeedManager
    }
    
    lazy var newsfeed:[SBANewsFeedItem] = {
       return self.newsfeedManager.feedPosts ?? []
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsfeed.count > 0 ? newsfeed.count : 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // If there aren't any news feed items then return the empty cell
        guard newsfeed.count > 0 else {
            tableView.separatorStyle = .None
            return tableView.dequeueReusableCellWithIdentifier("EmptyCell", forIndexPath: indexPath)
        }
        
        // Otherwise build the news feed cell
        tableView.separatorStyle = .SingleLine
        let cell = tableView.dequeueReusableCellWithIdentifier("NewsfeedCell", forIndexPath: indexPath)
        guard let newsCell = cell as? SBANewsfeedTableViewCell else { return cell }
        
        let item = newsfeed[indexPath.row]
        newsCell.titleLabel.text = item.title
        
        if let data = (item.itemDescription as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let attributedText = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                newsCell.subtitleLabel.text = attributedText.string
            } catch {
                newsCell.subtitleLabel.text = item.itemDescription
            }
        }
        
        newsCell.dateLabel.text = NSDateFormatter.localizedStringFromDate(item.pubDate, dateStyle: .ShortStyle, timeStyle: .NoStyle)
        newsCell.hasRead = newsfeedManager.hasUserReadPostWithURL(item.link)
        
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let cell = sender as? SBANewsfeedTableViewCell,
            let indexPath = self.tableView.indexPathForCell(cell) where indexPath.row < newsfeed.count,
            let vc = segue.destinationViewController as? SBAWebViewController {
            // Hook up the title and the url for the webview controller

            let newsItem = newsfeed[indexPath.row]
            vc.title = newsItem.title
            
            let encodedURLString = (newsItem.link as NSString).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            vc.url = NSURL(string: encodedURLString)
            
            newsfeedManager.userDidReadPostWithURL(newsItem.link)
            cell.hasRead = true
        }
    }

}
