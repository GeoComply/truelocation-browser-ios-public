//
//  UIFont.swift
//  Client
//
//  Created by Dat Hoang on 3/23/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation

extension UIFont {
    static func fireSanRegular(size: CGFloat = 16.0) -> UIFont {
        return UIFont(name: "FireSans-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func fireSanBold(size: CGFloat = 16.0) -> UIFont {
        return UIFont(name: "FireSans-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func openSanRegular(size: CGFloat = 16.0) -> UIFont {
        return UIFont(name: "OpenSans-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func openSanBold(size: CGFloat = 16.0) -> UIFont {
        return UIFont(name: "OpenSans-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
