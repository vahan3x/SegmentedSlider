//
//  SegmentReplicatorView.swift
//  SegmentedSlider
//
//  Created by Vahan Babayan on 11/8/18.
//  Copyright © 2018 vahan3x. All rights reserved.
//

import UIKit
import os.log

class SegmentReplicatorView: UIView {
    
    var segmentCount: UInt = 4 {
        didSet {
            guard segmentCount != oldValue else { return }
            
            updateAppearance()
        }
    }
    
    var segmentColor: UIColor = .white {
        didSet {
            [contentReplicatorLayer, leftReplicatorLayer, rightReplicatorLayer].forEach { $0.instanceColor = segmentColor.cgColor }
        }
    }
    
    var sectionCount: UInt = 1 {
        didSet {
            guard sectionCount != oldValue else { return }
            
            updateAppearance()
        }
    }
    
    var sectionWidth: CGFloat = 0.0 {
        didSet {
            guard sectionWidth != oldValue else { return }
            
            updateAppearance()
        }
    }
    
    var separatorLineWidth: CGFloat = 2.0 {
        didSet {
            if separatorLineWidth < 1.0 { separatorLineWidth = 1.0 }
            
            guard separatorLineHeightDifference >= -separatorLineWidth else {
                separatorLineHeightDifference = -separatorLineWidth // The setter will call `updateAppearance()`
                return
            }
            
            guard separatorLineWidth != oldValue else { return }
            
            updateAppearance()
        }
    }
    
    var separatorLineHeightDifference: CGFloat = 0.0 {
        didSet {
            if separatorLineHeightDifference < -separatorLineWidth { separatorLineHeightDifference = -separatorLineWidth }
            guard separatorLineHeightDifference != oldValue else { return }
            
            updateAppearance()
        }
    }
    
    private(set) var horizontalSegmentCenterDelta: CGFloat = 6.0
    
    override var bounds: CGRect {
        didSet {
            if bounds.height != oldValue.height { updateAppearance() }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: width,
                      height: UIView.noIntrinsicMetric)
    }
    
    private var separatorLineSpaceWidth: CGFloat = 4.0
    
    private var width: CGFloat = UIView.noIntrinsicMetric
    
    private lazy var contentReplicatorLayer: CAReplicatorLayer = {
        let replicator = SegmentReplicatorView.makeImageReplicatorLayer()
        replicator.instanceColor = segmentColor.cgColor
        layer.addSublayer(replicator)
        
        return replicator
    }()
    private lazy var leftReplicatorLayer: CAReplicatorLayer = {
        let replicator = SegmentReplicatorView.makeImageReplicatorLayer()
        replicator.opacity = 0.35
        replicator.transform = CATransform3DMakeScale(-1.0, 1.0, 1.0)
        replicator.instanceColor = segmentColor.cgColor
        layer.insertSublayer(replicator, below: contentReplicatorLayer)
        
        return replicator
    }()
    private lazy var rightReplicatorLayer: CAReplicatorLayer = {
        let replicator = SegmentReplicatorView.makeImageReplicatorLayer()
        replicator.opacity = 0.35
        replicator.position = CGPoint(x: layer.bounds.width, y: 0.0)
        replicator.instanceColor = segmentColor.cgColor
        layer.insertSublayer(replicator, below: contentReplicatorLayer)
        
        return replicator
    }()
    
    // MARK: - Methods
    
    private static func makeImageReplicatorLayer() -> CAReplicatorLayer {
        let replicator = CAReplicatorLayer()
        replicator.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        
        let imageLayer = CALayer()
        imageLayer.contentsScale = UIScreen.main.scale
        imageLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        
        replicator.addSublayer(imageLayer)
        
        return replicator
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        rightReplicatorLayer.position = CGPoint(x: layer.bounds.width, y: 0.0)
    }
    
    private func updateAppearance() {
        // The first two are for the section separators, the seconds are the spaces between the separators and the thirds are for the segment spearators
        var imageWidth = 2.0 * separatorLineWidth + CGFloat(segmentCount + 1) * separatorLineSpaceWidth + CGFloat(segmentCount) * separatorLineWidth
        if imageWidth < sectionWidth {
            separatorLineSpaceWidth = (sectionWidth - (2.0 * separatorLineWidth + CGFloat(segmentCount) * separatorLineWidth)) / CGFloat(segmentCount + 1)
            imageWidth = sectionWidth
        }
        
        let halfLineWidth = separatorLineWidth / 2.0
        let radius = halfLineWidth
        
        let segmentHeight = radius + 1.0 + radius
        let imageHeight = separatorLineHeightDifference + segmentHeight
        
        let imageBounds = CGRect(x: 0.0, y: 0.0, width: imageWidth, height: imageHeight)
        let image = UIGraphicsImageRenderer(bounds: imageBounds).image { (context) in
            UIColor.clear.setFill()
            context.fill(bounds)
            
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0.0, y: 0.0, width: separatorLineWidth, height: imageHeight), cornerRadius: CGFloat(radius)).fill()
            
            var x = separatorLineWidth
            let y = (imageHeight - segmentHeight) / 2.0
            UIColor(white: 1.0, alpha: 0.7).setFill()
            for _ in 0 ..< segmentCount {
                x += separatorLineSpaceWidth
                UIBezierPath(roundedRect: CGRect(x: x, y: y, width: separatorLineWidth, height: segmentHeight), cornerRadius: CGFloat(radius)).fill()
                x += separatorLineWidth
            }
            
            x += separatorLineSpaceWidth
            UIBezierPath(roundedRect: CGRect(x: x, y: 0.0, width: separatorLineWidth, height: imageHeight), cornerRadius: CGFloat(radius)).fill()
        }
        
        let imageLayerFrame = CGRect(x: -halfLineWidth, y: 0.0, width: imageWidth, height: bounds.height)
        
        let y = CGFloat(separatorLineHeightDifference / 2.0 + radius) / imageBounds.height
        [contentReplicatorLayer, leftReplicatorLayer, rightReplicatorLayer].forEach {
            guard let imageLayer = $0.sublayers?.first else { return }
            
            imageLayer.frame = imageLayerFrame
            imageLayer.contents = image.cgImage
            imageLayer.contentsCenter = CGRect(x: 0.0,
                                               y: y,
                                               width: 1.0,
                                               height: 1.0 - 2 * y)
            
            $0.instanceTransform = CATransform3DMakeTranslation(imageWidth - separatorLineWidth, 0.0, 0.0)
        }
        
        contentReplicatorLayer.instanceCount = Int(sectionCount)
        
        let shallowInstanceCount = Int(ceil(UIScreen.main.bounds.width / imageWidth))
        [leftReplicatorLayer, rightReplicatorLayer].forEach { $0.instanceCount = shallowInstanceCount }
        
        width = CGFloat(sectionCount) * (imageWidth - separatorLineWidth)
        rightReplicatorLayer.position = CGPoint(x: width, y: 0.0)
        horizontalSegmentCenterDelta = separatorLineWidth + separatorLineSpaceWidth
        
        invalidateIntrinsicContentSize()
    }
}
