//
//  HalfModalPresenterViewController.swift
//  HalfModalPresenter
//
//  Created by Raphael Bischof on 15/08/16.
//  Copyright © 2016 InAndWin. All rights reserved.
//

import UIKit

public protocol OpenedView {
    var closer:ContainerView? {get set}
}

public protocol ContainerView {
    func close()
}

public class HalfModalPresenterViewController:UIViewController {
    private var bubble:UIView?
    private var expandedPanel:UIView?
    private var transitionView:UIView?
    
    private var gesture:UITapGestureRecognizer?
    private var dismissHitBox:UIView?
    
    public func presentHalfScreenView(expandedPanel: UIView, transitionView: UIView){
        self.gesture = UITapGestureRecognizer(target: self, action: #selector(HalfModalPresenterViewController.dismissHalfScreenView))
        dismissHitBox = UIView(frame: self.view.frame)
        self.view.addSubview(dismissHitBox!)
        self.dismissHitBox!.addGestureRecognizer(gesture!)
        
        self.transitionView = transitionView
        self.expandedPanel = expandedPanel
        let center = transitionView.center
        if var expandedPanel = expandedPanel as? OpenedView,
            let delegate = self as? ContainerView {
            expandedPanel.closer = delegate
        }
        let screenHeight = UIScreen.mainScreen().bounds.height
        let screenWidth = UIScreen.mainScreen().bounds.width
        expandedPanel.frame = CGRectMake(0, screenHeight/2, screenWidth, screenHeight/2)
        let originalCenter = expandedPanel.center
        
        
        
        bubble = UIView()
        if let bubble = bubble {
            bubble.frame = CGRectMake(expandedPanel.frame.origin.x, expandedPanel.frame.origin.y, expandedPanel.frame.size.width+expandedPanel.frame.size.height, expandedPanel.frame.size.height)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.center = center
            bubble.transform = CGAffineTransformMakeScale(0.001, 0.001)
            bubble.backgroundColor = transitionView.backgroundColor
            bubble.clipsToBounds = true
            self.view.addSubview(bubble)
        }
        
        expandedPanel.center = center
        expandedPanel.transform = CGAffineTransformMakeScale(0.001, 0.001)
        expandedPanel.alpha = 0
        self.view.addSubview(expandedPanel)
        
        UIView.animateWithDuration(0.5, animations: {
            self.bubble!.transform = CGAffineTransformIdentity
            self.bubble!.frame = CGRectMake(-screenHeight/4, screenHeight/2, screenWidth+screenHeight/2, screenHeight/2)
            expandedPanel.transform = CGAffineTransformIdentity
            expandedPanel.alpha = 1
            expandedPanel.center = originalCenter
        }) { (_) in
        }
    }
    
    private func frameForBubble(originalCenter: CGPoint, size originalSize: CGSize, start: CGPoint) -> CGRect {
        let lengthX = fmax(start.x, originalSize.width - start.x);
        let lengthY = fmax(start.y, originalSize.height - start.y)
        let offset = sqrt(lengthX * lengthX + lengthY * lengthY) * 2;
        let size = CGSize(width: offset, height: offset)
        
        return CGRect(origin: CGPointZero, size: size)
    }
    
    public func dismissHalfScreenView() {
        if let returningControllerView = expandedPanel,
            let transitionView = transitionView{
            if let gesture = self.gesture,
                let dismissHitBox = self.dismissHitBox{
                dismissHitBox.removeGestureRecognizer(gesture)
                dismissHitBox.removeFromSuperview()
                self.gesture = nil
            }
            let originalCenter = returningControllerView.center
            
            let center = transitionView.center
            
            UIView.animateWithDuration(0.5, animations: {
                self.bubble!.transform = CGAffineTransformMakeScale(0.001, 0.001)
                self.bubble!.center = center
                returningControllerView.transform = CGAffineTransformMakeScale(0.001, 0.001)
                returningControllerView.center = center
                returningControllerView.alpha = 0
                
                self.view.insertSubview(returningControllerView, belowSubview: returningControllerView)
                self.view.insertSubview(self.bubble!, belowSubview: returningControllerView)
            }) { (_) in
                returningControllerView.center = originalCenter;
                returningControllerView.removeFromSuperview()
                self.bubble!.removeFromSuperview()
                self.bubble = nil
            }
        }
    }
}