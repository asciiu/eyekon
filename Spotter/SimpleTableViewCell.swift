//
//  SimpleTableViewCell.swift
//  Spotter
//
//  Created by LV426 on 9/16/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class SimpleTableViewCell: UITableViewCell {

    @IBOutlet var mainImage: UIImageView!
    @IBOutlet var annotationTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
