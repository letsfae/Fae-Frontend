//
//  PlacePinImagesView.swift
//  faeBeta
//
//  Created by Yue Shen on 5/31/18.
//  Copyright © 2018 fae. All rights reserved.
//

import UIKit
import CHIPageControl

class PlacePinImagesView: UIScrollView, UIScrollViewDelegate {
    
    var viewObjects = [UIImageView]()
    var numPages: Int = 0
    var pageControl: CHIPageControlAleppo?
    var currentPage = 0
    var prevPage = 0
    public var arrURLs = [String]() {
        didSet {
            numPages = arrURLs.count
        }
    }
    var arrSKPhoto = [SKPhoto]()
    var firstView: UIImageView!
    var lastView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isPagingEnabled = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func loadContent() {
        
        guard arrURLs.count > 0 else {
            let subView = UIImageView(frame: frame)
            subView.image = #imageLiteral(resourceName: "default_place")
            subView.contentMode = .scaleAspectFill
            subView.clipsToBounds = true
            viewObjects.append(subView)
            return
        }
        
        for index in 0..<arrURLs.count {
            let subView = UIImageView(frame: frame)
            subView.contentMode = .scaleAspectFill
            subView.clipsToBounds = true
            viewObjects.append(subView)
            let photo = SKPhoto(url: arrURLs[index])
            arrSKPhoto.append(photo)
            subView.sd_setShowActivityIndicatorView(true)
            subView.backgroundColor = ._210210210()
            subView.image = nil
            subView.sd_setImage(with: URL(string: arrURLs[index]), placeholderImage: nil, options: [.retryFailed]) { (img, err, _, _) in
                if img == nil || err != nil {
                    subView.image = Key.shared.defaultPlace
                }
                subView.sd_setShowActivityIndicatorView(false)
            }
            if index == 0 {
                firstView = UIImageView(frame: frame)
                firstView.frame.origin.x = frame.size.width * (CGFloat(arrURLs.count) - 1)
                firstView.contentMode = .scaleAspectFill
                firstView.clipsToBounds = true
                firstView.sd_setShowActivityIndicatorView(true)
                firstView.backgroundColor = ._210210210()
                firstView.image = nil
                firstView.sd_setImage(with: URL(string: arrURLs[index]), placeholderImage: nil, options: [.retryFailed]) { [weak self] (img, err, _, _) in
                    if img == nil || err != nil {
                        self?.firstView.image = Key.shared.defaultPlace
                    }
                    self?.firstView.sd_setShowActivityIndicatorView(false)
                }
                addSubview(firstView)
            } else if index == arrURLs.count - 1 {
                lastView = UIImageView(frame: frame)
                lastView.frame.origin.x = 0
                lastView.contentMode = .scaleAspectFill
                lastView.clipsToBounds = true
                lastView.sd_setShowActivityIndicatorView(true)
                lastView.backgroundColor = ._210210210()
                lastView.image = nil
                lastView.sd_setImage(with: URL(string: arrURLs[index]), placeholderImage: nil, options: [.retryFailed]) { [weak self] (img, err, _, _) in
                    if img == nil || err != nil {
                        self?.lastView.image = Key.shared.defaultPlace
                    }
                    self?.lastView.sd_setShowActivityIndicatorView(false)
                }
                addSubview(lastView)
            }
        }
    }
    
    public func setup() {
        guard arrURLs.count > 1 else {
            numPages = 1
            loadScrollViewWithPage(0)
            return
        }
        
        contentSize = CGSize(width: (frame.size.width * (CGFloat(numPages) + 2)), height: frame.size.height)
        
        loadPageCtrl()
        
        loadScrollViewWithPage(0)
        loadScrollViewWithPage(1)
        loadScrollViewWithPage(2)
        
        var newFrame = frame
        newFrame.origin.x = newFrame.size.width
        newFrame.origin.y = 0
        scrollRectToVisible(newFrame, animated: false)
        
        layoutIfNeeded()
    }
    
    func loadPageCtrl() {
        guard let parent = superview else { return }
        pageControl = CHIPageControlAleppo(frame: CGRect(x: 0, y: frame.size.height-25, width: frame.size.width, height: 25))
        pageControl?.radius = 4
        pageControl?.tintColor = .white
        pageControl?.currentPageTintColor = .white
        pageControl?.padding = 6
        pageControl?.hidesForSinglePage = true
        pageControl?.isUserInteractionEnabled = false
        parent.addSubview(pageControl!)
        pageControl?.numberOfPages = numPages
        prevPage = numPages
        pageControl?.set(progress: currentPage, animated: false)
    }
    
    private func loadScrollViewWithPage(_ page: Int) {
        if page < 0 { return }
        if page >= numPages + 2 { return }
        
        var index = 0
        
        if page == 0 {
            index = numPages - 1
        } else if page == numPages + 1 {
            index = 0
        } else {
            index = page - 1
        }
        
        let view = viewObjects[index]
        
        var newFrame = frame
        newFrame.origin.x = frame.size.width * CGFloat(page)
        newFrame.origin.y = 0
        view.frame = newFrame
        
        if view.superview == nil {
            addSubview(view)
        }
        
        layoutIfNeeded()
    }
    
    public func updateContent(_ index: Int) {
        let pageWidth = frame.size.width
        contentOffset = CGPoint(x: pageWidth*(CGFloat(index+1)), y: 0)
        currentPage = index
        pageControl?.set(progress: index, animated: false)
    }
    
    // MARK: - UIScrollView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x >= frame.size.width / 2 && scrollView.contentOffset.x <= frame.size.width {
            lastView.isHidden = false
        } else if scrollView.contentOffset.x >= frame.size.width * (CGFloat(arrURLs.count) - 0.5) && scrollView.contentOffset.x <= frame.size.width * CGFloat(arrURLs.count) {
            firstView.isHidden = false
        } else {
            lastView.isHidden = true
            firstView.isHidden = true
        }
        let pageWidth = frame.size.width
        let page = floor((contentOffset.x - (pageWidth/2)) / pageWidth) + 1
        loadScrollViewWithPage(Int(page - 1))
        loadScrollViewWithPage(Int(page))
        loadScrollViewWithPage(Int(page + 1))
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = frame.size.width
        let page: Int = Int(floor((contentOffset.x - (pageWidth/2)) / pageWidth) + 1)
        currentPage = Int(page - 1)
        if prevPage == -1 && currentPage == numPages {
            pageControl?.set(progress: 0, animated: false)
        } else if prevPage == numPages - 1 && currentPage == numPages {
            pageControl?.set(progress: 0, animated: false)
        } else if prevPage == 0 && currentPage == -1 {
            pageControl?.set(progress: numPages - 1, animated: false)
        } else if prevPage == numPages && currentPage == -1 {
            pageControl?.set(progress: numPages - 1, animated: false)
        } else {
            pageControl?.set(progress: Int(page - 1), animated: true)
        }
        prevPage = currentPage
        if page == 0 {
            contentOffset = CGPoint(x: pageWidth*(CGFloat(numPages)), y: 0)
        } else if page == numPages+1 {
            contentOffset = CGPoint(x: pageWidth, y: 0)
        }
        if currentPage == viewObjects.count {
            currentPage = 0
        } else if currentPage == -1 {
            currentPage = viewObjects.count - 1
        }
    }
}
