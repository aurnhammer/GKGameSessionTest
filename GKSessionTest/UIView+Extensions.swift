//
//  UIView+Extensions.swift
//  GKSessionTest
//
//  Created by Bill A on 3/15/17.
//  Copyright © 2017 aurnhammer. All rights reserved.
//

import UIKit

@IBDesignable

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
}
