//
//  SegmentedSlider.swift
//  SegmentedSlider
//
//  Created by Vahan Babayan on 9/1/18.
//  Copyright © 2018 vahan3x. All rights reserved.
//

import UIKit
import os.log

/// A control to select a single value from continuous range of values.
/// Designed to display the range as a sequence of sections divided into segments.
/// - BUG: `UIControl`'s tracking behaviour is currently not working.
@IBDesignable public class SegmentedSlider: UIControl {
    
    // MARK: - Variables
    
    /// The slider's current value. Default is `0.5`.
    ///
    /// Use this property to get and set the slider's current value.
    /// - Note: To change the slider's value by transitioning it's appearance use `set(value:,animated:)`.
    /// - Note: If you try to set a value that is beyond the slider's acceptable range, it'll be clamped
    /// into it.
    /// - Note: The value may change if you'll change `minimumValue` or `maximumValue`.
    @IBInspectable public var value: Double {
        get { return actualValue }
        set {
            var value = newValue
            if !((minimumValue ... maximumValue) ~= value) {
                value = min(maximumValue, max(value, minimumValue))
            }
            
            guard value != actualValue else { return }
            
            actualValue = value

            let offset = CGPoint(x: -scrollView.contentInset.left + (valueProgress * scrollView.contentSize.width), y: 0.0)
            
            os_log("Setting: %@", type: .debug, "\(offset)")
                        
            performWithoutUpdatingValue { scrollView.contentOffset = offset }
        }
    }
    
    private var actualValue: Double = 0.5
    
    private var valueProgress: CGFloat {
        guard maximumValue != minimumValue else { return 0.0 }
        return CGFloat(actualValue / (maximumValue - minimumValue))
    }
    
    /// The lower bound of the slider's range. Default is `0.0`.
    ///
    /// Use this property to get and set the slider's acceptable range's lower bound.
    /// - Note: The value may change if you'll change `maximumValue`.
    @IBInspectable public var minimumValue: Double = 0.0 {
        didSet {
            if value < minimumValue {
                value = minimumValue
                
                if maximumValue < minimumValue {
                    maximumValue = minimumValue
                }
            }
        }
    }
    
    /// The upper bound of the slider's range. Default is `1.0`.
    ///
    /// Use this property to get and set the slider's accpetable range's upper bound.
    /// - Note: The value may change if you'll change `minimumValue`.
    @IBInspectable public var maximumValue: Double = 1.0 {
        didSet {
            if value > maximumValue {
                value = maximumValue
                
                if minimumValue > maximumValue {
                    minimumValue = maximumValue
                }
            }
        }
    }
    
    /// A number of segments in each section. Default is `4`.
    @IBInspectable public var segmentCount: UInt = 4 { didSet { updateAppearance() } }
    
    /// A color of the segment separators. Default is `.white`.
    @IBInspectable public var segmentColor: UIColor = .white { didSet { replicatorLayer.instanceColor = segmentColor.cgColor } }
    
    /// A number of sections to divide the slider's range into. Default is `1`.
    @IBInspectable public var sectionCount: UInt = 1 { didSet { updateAppearance() } }
    
    /// Width of the slider's single section in points. Default is `0.0`.
    ///
    /// Use this property to customize sensitivity of the slider.
    /// - Note: Values less then a minimum width needed to separate section segments will be ignored.
    @IBInspectable public var sectionWidth: CGFloat = 0.0 { didSet { updateAppearance() } }
    
    /// Width of the slider's section and segment separator lines in points. Default is `2.0`.
    ///
    /// Use this property to customize the slider's appearance.
    /// - Note: Values less then `1.0` will be ignored.
    @IBInspectable public var separatorLineWidth: CGFloat = 2.0 {
        didSet {
            if separatorLineWidth < 1.0 { separatorLineWidth = 1.0 }
            
            guard separatorLineHeightDifference >= -separatorLineWidth else {
                separatorLineHeightDifference = -separatorLineWidth // The setter will call `updateAppearance()`
                return
            }
            
            updateAppearance()
        }
    }
    
    /// Height difference of the section and segment separator lines in points. default is `0.0`.
    ///
    /// Use this property to customize the slider's appearance.
    /// - Note: Values less then `-separatorLineWidth` will be ignored.
    @IBInspectable public var separatorLineHeightDifference: CGFloat = 0.0 {
        didSet {
            if separatorLineHeightDifference < -separatorLineWidth { separatorLineHeightDifference = -separatorLineWidth }
            
            updateAppearance()
        }
    }
    
    /// A Boolean value indicating whether the slider is currently tracking touch events.
    ///
    /// While tracking of a touch event is in progress, the slider sets the value of this property
    /// to `true`. When tracking ends or is cancelled for any reason, it sets this property to `false`.
    public override var isTracking: Bool { return super.isTracking || scrollView.panGestureRecognizer.state != .possible }
    
    /// A Boolean value indicating whether a tracked touch event is currently inside the slider’s bounds.
    ///
    /// While tracking of a touch event is ongoing, the slider updates the value of this property to indicate
    /// whether the most recent touch is still inside the slider’s bounds. The slider uses this information to trigger
    /// specific events. For example, touch events entering or exiting a slider trigger appropriate drag events.
    public override var isTouchInside: Bool { return super.isTouchInside || (scrollView.panGestureRecognizer.state != .possible && wasLastTouchInside) }
    
    private let replicatorLayer = CAReplicatorLayer()
    private let imageLayer = CALayer()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var contentViewWidthConstraint: NSLayoutConstraint!
    private var indicatorLayer = CALayer()
    
    private var separatorLineSpaceWidth: CGFloat = 4.0
    private var wasLastTouchInside = true
    private var shouldUpdateValue = true
    
    /// By some reasons after `layoutSubviews()` is called, `contentView`'s size is still undefined, so I moved the
    /// content size-dependent code here.
    private lazy var scrollViewContentObservation = scrollView.observe(\.contentSize) { [weak self] (scrollView, change) in
        guard let gelf = self else { return }
        
        gelf.replicatorLayer.bounds = CGRect(x: gelf.replicatorLayer.bounds.origin.x,
                                             y: gelf.replicatorLayer.bounds.origin.y,
                                             width: gelf.replicatorLayer.bounds.width,
                                             height: scrollView.contentSize.height)
        gelf.replicatorLayer.position = CGPoint(x: scrollView.contentSize.width / 2.0 - gelf.separatorLineWidth / 2.0,
                                                y: scrollView.contentSize.height / 2.0)
        gelf.imageLayer.frame = CGRect(x: 0.0, y: 0.0,
                                       width: gelf.imageLayer.bounds.width,
                                       height: gelf.replicatorLayer.bounds.height)
        
        
        let offset = CGPoint(x: -scrollView.contentInset.left + (gelf.valueProgress * scrollView.contentSize.width), y: 0.0)
        
        os_log("Setting: %@", type: .debug, "\(offset)")
        gelf.performWithoutUpdatingValue { scrollView.contentOffset = offset }
    }
    
    // MARK: - Methods
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        if backgroundColor == nil {
            backgroundColor = .clear
        }
    }
    
    private func setup() {
        _ = scrollViewContentObservation
        backgroundColor = .clear
        
        contentView.backgroundColor = .clear
        contentView.layer.addSublayer(replicatorLayer)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(scrollViewPanAction(_:)))
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        addSubview(scrollView)
        scrollView.delegate = self
        contentViewWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 0.0)
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalTo: heightAnchor),
            contentViewWidthConstraint,
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            scrollView.centerXAnchor.constraint(equalTo: centerXAnchor),
            scrollView.centerYAnchor.constraint(equalTo: centerYAnchor),
            scrollView.widthAnchor.constraint(equalTo: widthAnchor),
            scrollView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
        
        replicatorLayer.addSublayer(imageLayer)
        
        indicatorLayer.mask = CALayer()
        indicatorLayer.backgroundColor = tintColor.cgColor
        layer.addSublayer(indicatorLayer)
        
        updateAppearance()
    }
    
    public override var intrinsicContentSize: CGSize { return CGSize(width: UIView.noIntrinsicMetric, height: 30.0) }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        performWithoutUpdatingValue { scrollView.contentInset = UIEdgeInsets(top: 0.0, left: bounds.width / 2.0, bottom: 0.0, right: bounds.width / 2.0) }

        indicatorLayer.bounds = CGRect(x: 0.0, y: 0.0, width: separatorLineWidth, height: layer.bounds.height)
        indicatorLayer.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        indicatorLayer.mask?.frame = indicatorLayer.bounds
    }
    
    public override func tintColorDidChange() {
        super.tintColorDidChange()
        indicatorLayer.backgroundColor = tintColor.cgColor
    }
    
    private func updateAppearance() {
        // The first one is for a section separator, the seconds are the spaces between the separators and the thirds are for the segment spearators
        var width = 1.0 * separatorLineWidth + CGFloat(segmentCount) * separatorLineSpaceWidth + CGFloat(segmentCount) * separatorLineWidth
        if width < sectionWidth {
            separatorLineSpaceWidth = (sectionWidth - (1.0 * separatorLineWidth + CGFloat(segmentCount) * separatorLineWidth)) / CGFloat(segmentCount)
            width = sectionWidth
        }
        
        let halfLineWidth = separatorLineWidth / 2.0
        let radius = halfLineWidth
        
        let segmentHeight = radius + 1.0 + radius
        let height = radius + separatorLineHeightDifference + segmentHeight + radius
        
        let bounds = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        let image = UIGraphicsImageRenderer(bounds: bounds).image { (context) in
            UIColor.clear.setFill()
            context.fill(bounds)
            
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0.0, y: 0.0, width: separatorLineWidth, height: height), cornerRadius: CGFloat(radius)).fill()
            
            var x = separatorLineWidth
            let y = (height - segmentHeight) / 2.0
            UIColor(white: 1.0, alpha: 0.7).setFill()
            for _ in 0 ..< segmentCount {
                x += separatorLineSpaceWidth
                UIBezierPath(roundedRect: CGRect(x: x, y: y, width: separatorLineWidth, height: segmentHeight), cornerRadius: CGFloat(radius)).fill()
                x += separatorLineWidth
            }
        }
        
        indicatorLayer.mask?.contents = UIGraphicsImageRenderer(bounds: CGRect(x: 0.0, y: 0.0, width: separatorLineWidth, height: segmentHeight)).image { (context) in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0.0, y: 0.0, width: separatorLineWidth, height: segmentHeight), cornerRadius: CGFloat(radius)).fill()
        }.cgImage
        indicatorLayer.mask?.contentsScale = UIScreen.main.scale
        indicatorLayer.mask?.contentsCenter = CGRect(x: 0.0, y: radius / segmentHeight, width: 1.0, height: 1.0 / segmentHeight)
        
        imageLayer.bounds = CGRect(x: imageLayer.bounds.origin.x, y: imageLayer.bounds.origin.y, width: bounds.width, height: imageLayer.bounds.height)
        imageLayer.contentsScale = UIScreen.main.scale
        imageLayer.contentsCenter = CGRect(x: 0.0,
                                           y: CGFloat((height - segmentHeight) / 2.0 + radius) / bounds.height,
                                           width: 1.0,
                                           height: 1.0 / bounds.height)
        imageLayer.contents = image.cgImage
        
        replicatorLayer.instanceColor = segmentColor.cgColor
        replicatorLayer.instanceCount = Int(sectionCount) + 2 * Int(UIScreen.main.bounds.width / bounds.width)
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(bounds.width + separatorLineSpaceWidth, 0.0, 0.0)
        replicatorLayer.bounds = CGRect(x: replicatorLayer.bounds.origin.x,
                                        y: replicatorLayer.bounds.origin.y,
                                        width: CGFloat(replicatorLayer.instanceCount) * (bounds.width + separatorLineSpaceWidth),
                                        height: replicatorLayer.bounds.height)
        
        contentViewWidthConstraint.constant = (bounds.width + separatorLineSpaceWidth) * CGFloat(sectionCount)
        
        scrollView.contentOffset = CGPoint(x: -scrollView.contentInset.left + (valueProgress * scrollView.contentSize.width), y: 0.0)
    }
    
    /// Set's the slider's current value, optionally animating the transition.
    ///
    /// - Parameters:
    ///   - value: A new value to assign to `value` property.
    ///   - animated: A boolean value indicating whether the value change should be animated.
    /// Default is `true`.
    public func set(value: Double, animated: Bool = true) {
        // TODO:
        fatalError("Not implemented.")
    }
    
    private func performWithoutUpdatingValue(_ action: () -> Void) {
        shouldUpdateValue = false
        action()
        shouldUpdateValue = true
    }
    
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        // TODO: Need to make the tracking methods call in order to support `UIControl` actions.
        return super.beginTracking(touch, with: event)
    }
    
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return super.continueTracking(touch, with: event)
    }
    
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
    }
    
    public override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
    }
    
    // MARK: Actions
    
    @objc private func scrollViewPanAction(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            sendActions(for: [.touchDown])
            wasLastTouchInside = true
        case .changed:
            switch (self.bounds.contains(sender.location(in: self)), wasLastTouchInside) {
            case (false, false): sendActions(for: [.touchDragOutside])
            case (true, false):
                sendActions(for: [.touchDragEnter])
                wasLastTouchInside = true
            case (false, true):
                sendActions(for: [.touchDragExit])
                wasLastTouchInside = false
            case (true, true): sendActions(for: [.touchDragInside])
            }
        case .ended:
            if self.bounds.contains(sender.location(in: self)) {
                sendActions(for: [.touchUpInside])
            } else {
                sendActions(for: [.touchUpOutside])
            }
        case .cancelled: sendActions(for: [.touchCancel])
        default: break
        }
    }
}

private typealias ScrollDelegate = SegmentedSlider
extension ScrollDelegate: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        os_log("Setted: %@", type: .debug, "\(scrollView.contentOffset)") // BUG: the value doesn't match with the setted one.
        let progress = Double((scrollView.contentOffset.x + scrollView.contentInset.left) / scrollView.contentSize.width)
        os_log("Progress: %@", type: .debug, "\(progress)")
        
        guard shouldUpdateValue else { return }
        
        let newValue = min(1.0, max(0.0, progress)) * (maximumValue - minimumValue)
        guard newValue != actualValue else { return }
        actualValue = newValue
        sendActions(for: [.valueChanged])
    }
}
