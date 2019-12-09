//
//  killbutton.swift
//  HomeRobot
//
//  Created by Ferdinand Lösch on 28/10/2019.
//  Copyright © 2019 Laan Labs. All rights reserved.
//

import Foundation
import UIKit

protocol SlideButtonDelegate {
    func buttonStatus(status: String, sender: MMSlidingButton)
}

@IBDesignable class MMSlidingButton: UIView {
    var delegate: SlideButtonDelegate?

    @IBInspectable var dragPointWidth: CGFloat = 70 {
        didSet {
            setStyle()
        }
    }

    @IBInspectable var dragPointColor: UIColor = UIColor.darkGray {
        didSet {
            setStyle()
        }
    }

    @IBInspectable var buttonColor: UIColor = UIColor.gray {
        didSet {
            setStyle()
        }
    }

    @IBInspectable var buttonText: String = "UNLOCK" {
        didSet {
            setStyle()
        }
    }

    @IBInspectable var imageName: UIImage = UIImage() {
        didSet {
            setStyle()
        }
    }

    @IBInspectable var buttonTextColor: UIColor = UIColor.white {
        didSet {
            setStyle()
        }
    }

    @IBInspectable var dragPointTextColor: UIColor = UIColor.white {
        didSet {
            setStyle()
        }
    }

    @IBInspectable var buttonUnlockedTextColor: UIColor = UIColor.white {
        didSet {
            setStyle()
        }
    }

    @IBInspectable var buttonCornerRadius: CGFloat = 30 {
        didSet {
            setStyle()
        }
    }

    @IBInspectable var buttonUnlockedText: String = "UNLOCKED"
    @IBInspectable var buttonUnlockedColor: UIColor = UIColor.black
    var buttonFont = UIFont.boldSystemFont(ofSize: 17)

    var dragPoint = UIView()
    var buttonLabel = UILabel()
    var dragPointButtonLabel = UILabel()
    var imageView = UIImageView()
    var unlocked = false
    var layoutSet = false

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    override func layoutSubviews() {
        if !layoutSet {
            setUpButton()
            layoutSet = true
        }
    }

    func setStyle() {
        buttonLabel.text = buttonText
        dragPointButtonLabel.text = buttonText
        dragPoint.frame.size.width = dragPointWidth
        dragPoint.backgroundColor = dragPointColor
        backgroundColor = buttonColor
        imageView.image = imageName
        buttonLabel.textColor = buttonTextColor
        dragPointButtonLabel.textColor = dragPointTextColor

        dragPoint.layer.cornerRadius = buttonCornerRadius
        layer.cornerRadius = buttonCornerRadius
    }

    func setUpButton() {
        backgroundColor = buttonColor

        dragPoint = UIView(frame: CGRect(x: dragPointWidth - frame.size.width, y: 0, width: frame.size.width, height: frame.size.height))
        dragPoint.backgroundColor = dragPointColor
        dragPoint.layer.cornerRadius = buttonCornerRadius
        addSubview(dragPoint)

        if !buttonText.isEmpty {
            buttonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
            buttonLabel.textAlignment = .center
            buttonLabel.text = buttonText
            buttonLabel.textColor = UIColor.white
            buttonLabel.font = buttonFont
            buttonLabel.textColor = buttonTextColor
            addSubview(buttonLabel)

            dragPointButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
            dragPointButtonLabel.textAlignment = .center
            dragPointButtonLabel.text = buttonText
            dragPointButtonLabel.textColor = UIColor.white
            dragPointButtonLabel.font = buttonFont
            dragPointButtonLabel.textColor = dragPointTextColor
            dragPoint.addSubview(dragPointButtonLabel)
        }
        bringSubviewToFront(dragPoint)

        if imageName != UIImage() {
            imageView = UIImageView(frame: CGRect(x: frame.size.width - dragPointWidth, y: 0, width: dragPointWidth, height: frame.size.height))
            imageView.contentMode = .center
            imageView.image = imageName
            dragPoint.addSubview(imageView)
        }

        layer.masksToBounds = true

        // start detecting pan gesture
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panDetected(sender:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        dragPoint.addGestureRecognizer(panGestureRecognizer)
    }

    @objc func panDetected(sender: UIPanGestureRecognizer) {
        var translatedPoint = sender.translation(in: self)
        translatedPoint = CGPoint(x: translatedPoint.x, y: frame.size.height / 2)
        sender.view?.frame.origin.x = (dragPointWidth - frame.size.width) + translatedPoint.x
        if sender.state == .ended {
            let velocityX = sender.velocity(in: self).x * 0.2
            var finalX = translatedPoint.x + velocityX
            if finalX < 0 {
                finalX = 0
            } else if finalX + dragPointWidth > (frame.size.width - 60) {
                unlocked = true
                unlock()
            }

            let animationDuration: Double = abs(Double(velocityX) * 0.0002) + 0.2
            UIView.transition(with: self, duration: animationDuration, options: UIView.AnimationOptions.curveEaseOut, animations: {}, completion: { Status in
                if Status {
                    self.animationFinished()
                }
            })
        }
    }

    func animationFinished() {
        if !unlocked {
            reset()
        }
    }

    // lock button animation (SUCCESS)
    func unlock() {
        UIView.transition(with: self, duration: 0.2, options: .curveEaseOut, animations: {
            self.dragPoint.frame = CGRect(x: self.frame.size.width - self.dragPoint.frame.size.width, y: 0, width: self.dragPoint.frame.size.width, height: self.dragPoint.frame.size.height)
        }) { Status in
            if Status {
                self.dragPointButtonLabel.text = self.buttonUnlockedText
                self.imageView.isHidden = true
                self.dragPoint.backgroundColor = self.buttonUnlockedColor
                self.dragPointButtonLabel.textColor = self.buttonUnlockedTextColor
                self.delegate?.buttonStatus(status: "Unlocked", sender: self)
            }
        }
    }

    // reset button animation (RESET)
    func reset() {
        UIView.transition(with: self, duration: 0.2, options: .curveEaseOut, animations: {
            self.dragPoint.frame = CGRect(x: self.dragPointWidth - self.frame.size.width, y: 0, width: self.dragPoint.frame.size.width, height: self.dragPoint.frame.size.height)
        }) { Status in
            if Status {
                self.dragPointButtonLabel.text = self.buttonText
                self.imageView.isHidden = false
                self.dragPoint.backgroundColor = self.dragPointColor
                self.dragPointButtonLabel.textColor = self.dragPointTextColor
                self.unlocked = false
                // self.delegate?.buttonStatus("Locked")
            }
        }
    }
}
