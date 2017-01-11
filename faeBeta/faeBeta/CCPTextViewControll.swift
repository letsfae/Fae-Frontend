//
//  CCPTextViewControll.swift
//  faeBeta
//
//  Created by Yue on 11/15/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit

extension CreateCommentPinViewController: UITextViewDelegate {
    
    func tapOutsideToDismissKeyboard(_ sender: UITapGestureRecognizer) {
        textViewForCommentPin.endEditing(true)
        textViewForCommentPin.resignFirstResponder()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        inputToolbar.numberOfCharactersEntered = max(0,textView.text.characters.count)
        if isShowingEmoji == true {
            isShowingEmoji = false
            UIView.animate(withDuration: 0.3, animations: {
                self.emojiView.frame.origin.y = screenHeight
            }, completion: { (Completed) in
                self.inputToolbar.buttonOpenFaceGesPanel.setImage(#imageLiteral(resourceName: "faeGesture_filled"), for: UIControlState())
            })
            self.textViewForCommentPin.becomeFirstResponder()
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == textViewForCommentPin {
            let spacing = CharacterSet.whitespacesAndNewlines
            
            if textViewForCommentPin.text.trimmingCharacters(in: spacing).isEmpty == false {
                buttonCommentSubmit.isEnabled = true
                lableTextViewPlaceholder.isHidden = true
                buttonCommentSubmit.backgroundColor = UIColor(red: 182/255, green: 159/255, blue: 202/255, alpha: 1.0)
                buttonCommentSubmit.setTitleColor(UIColor.white, for: UIControlState())
            }
            else {
                buttonCommentSubmit.isEnabled = false
                lableTextViewPlaceholder.isHidden = false
                buttonCommentSubmit.backgroundColor = UIColor(red: 182/255, green: 159/255, blue: 202/255, alpha: 0.65)
                buttonCommentSubmit.setTitleColor(UIColor(red: 1, green: 1, blue: 1, alpha: 0.65), for: UIControlState())
            }
            let numLines = Int(textView.contentSize.height / textView.font!.lineHeight)
            var numlineOnDevice = 3
            if screenWidth == 375 {
                numlineOnDevice = 4
            }
            else if screenWidth == 414 {
                numlineOnDevice = 7
            }
            if numLines <= numlineOnDevice {
                let fixedWidth = textView.frame.size.width
                textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
                var newFrame = textView.frame
                newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
                textView.frame = newFrame
                textView.isScrollEnabled = false
            }
            else if numLines > numlineOnDevice {
                textView.isScrollEnabled = true
            }
            inputToolbar.numberOfCharactersEntered = max(0,textView.text.characters.count) //This changes the number showed in labelCountChar
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == textViewForCommentPin {
            if (text == "\n")  {
                textViewForCommentPin.resignFirstResponder()
                return false
            }
            let countChars = textView.text.characters.count + (text.characters.count - range.length)
            return countChars <= 200
        }
        return true
    }
}
