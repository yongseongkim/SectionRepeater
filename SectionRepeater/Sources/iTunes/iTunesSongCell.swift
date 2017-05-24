//
//  iTunesSongCell.swift
//  SectionRepeater
//
//  Created by KimYongSeong on 2017. 2. 7..
//  Copyright © 2017년 yongseongkim. All rights reserved.
//

import UIKit
import MediaPlayer

class iTunesSongCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var seperateViewHeightConstraint: NSLayoutConstraint!
    
    
    var item: MPMediaItem? {
        didSet {
            if let item = item {
                self.titleLabel.text = item.title
                self.artistNameLabel.text = item.artist
                self.coverImageView.image = item.artwork?.image(at: coverImageView.frame.size)
            } else {
                self.titleLabel.text = ""
                self.artistNameLabel.text = ""
                self.coverImageView.image = nil
            }
        }
    }
    
    class func height() -> CGFloat {
        return 50
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.coverImageView.layer.borderColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0).cgColor
        self.coverImageView.layer.borderWidth = 0.5
        self.seperateViewHeightConstraint.constant = 0.5
    }

}