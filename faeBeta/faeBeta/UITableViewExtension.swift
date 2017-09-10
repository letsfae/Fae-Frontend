//
//  UITableViewExtension.swift
//  faeBeta
//
//  Created by Yue Shen on 8/30/17.
//  Copyright © 2017 fae. All rights reserved.
//

import UIKit

extension UITableView {
    /// Perform a series of method calls that insert, delete, or select rows and sections of the table view.
    /// This is equivalent to a beginUpdates() / endUpdates() sequence,
    /// with a completion closure when the animation is finished.
    /// Parameter update: the update operation to perform on the tableView.
    /// Parameter completion: the completion closure to be executed when the animation is completed.
    
    func performUpdate(_ update: () -> Void, completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        // Table View update on row / section
        beginUpdates()
        update()
        endUpdates()
        CATransaction.commit()
    }
}