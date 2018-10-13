//
//  CustomLabel.swift
//  FairRide
//
//  Created by Stephen Fung on 8/15/18.
//  Copyright © 2018 Stephen Fung. All rights reserved.
//

import UIKit

class CustomLabel: UILabel{
    override var text: String?{
        didSet {
            if let text = text {
                print("Text changed.")
                
            } else {
                print("Text not changed.")
            }
        }
    }
}
