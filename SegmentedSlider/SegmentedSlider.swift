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
            
            performWithoutUpdatingValue { updateScrollViewOffset() }
        }
    }
    
    private var actualValue: Double = 0.5
    
    private var valueProgress: CGFloat {
        guard maximumValue != minimumValue else { return 0.0 }
        return CGFloat((actualValue - minimumValue) / (maximumValue - minimumValue))
    }
    
    /// The lower bound of the slider's range. Default is `0.0`.
    ///
    /// Use this property to get and set the slider's acceptable range's lower bound.
    /// - Note: The value may change if you'll change `maximumValue`.
    @IBInspectable public var minimumValue: Double = 0.0 {
        didSet {
            if maximumValue < minimumValue {
                maximumValue = minimumValue
            }
            
            if value < minimumValue {
                value = minimumValue    
            }
        }
    }
    
    /// The upper bound of the slider's range. Default is `1.0`.
    ///
    /// Use this property to get and set the slider's accpetable range's upper bound.
    /// - Note: The value may change if you'll change `minimumValue`.
    @IBInspectable public var maximumValue: Double = 1.0 {
        didSet {
            if minimumValue > maximumValue {
                minimumValue = maximumValue
            }
            
            if value > maximumValue {
                value = maximumValue
            }
        }
    }
    
    /// A number of segments in each section. Default is `4`.
    @IBInspectable public var segmentCount: UInt {
        set { segmentReplicatorView.segmentCount = newValue }
        get { return segmentReplicatorView.segmentCount }
    }
    
    /// A color of the segment separators. Default is `.white`.
    @IBInspectable public var segmentColor: UIColor {
        set { segmentReplicatorView.segmentColor = newValue }
        get { return segmentReplicatorView.segmentColor }}
    
    /// A number of sections to divide the slider's range into. Default is `1`.
    @IBInspectable public var sectionCount: UInt {
        set { segmentReplicatorView.sectionCount = newValue }
        get { return segmentReplicatorView.sectionCount }
    }
    
    /// Width of the slider's single section in points. Default is `0.0`.
    ///
    /// Use this property to customize sensitivity of the slider.
    /// - Note: Values less then a minimum width needed to separate section segments will be ignored.
    @IBInspectable public var sectionWidth: CGFloat {
        set { segmentReplicatorView.sectionWidth = newValue }
        get { return segmentReplicatorView.sectionWidth }
    }
    
    /// Width of the slider's section and segment separator lines in points. Default is `2.0`.
    ///
    /// Use this property to customize the slider's appearance.
    /// - Note: Values less then `1.0` will be ignored.
    @IBInspectable public var separatorLineWidth: CGFloat {
        set {
            segmentReplicatorView.separatorLineWidth = newValue
            updateIndiciatorLayer()
        }
        get { return segmentReplicatorView.separatorLineWidth }
    }
    
    /// Height difference of the section and segment separator lines in points. default is `0.0`.
    ///
    /// Use this property to customize the slider's appearance.
    /// - Note: Values less then `-separatorLineWidth` will be ignored.
    @IBInspectable public var separatorLineHeightDifference: CGFloat {
        set { segmentReplicatorView.separatorLineHeightDifference = newValue }
        get { return segmentReplicatorView.separatorLineHeightDifference }
    }
    
    @IBInspectable public override var isEnabled: Bool {
        didSet {
            scrollView.isScrollEnabled = isEnabled
            scrollView.alpha = isEnabled ? 1.0 : 0.75
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
    
    /// A Boolean value indicating whether the slider is still decelerating after the last slide.
    ///
    /// After the touch was released the slider may bounce with deceleration, in that case it sets this property to `true`
    /// until the deceleration is over.
    public private(set) var isDecelerating: Bool = false
    
    public override var intrinsicContentSize: CGSize { return CGSize(width: UIView.noIntrinsicMetric, height: 30.0) }
    
    private let scrollView = UIScrollView()
    private let indicatorLayer = CALayer()
    private let segmentReplicatorView = SegmentReplicatorView()
    
    private var separatorLineSpaceWidth: CGFloat = 4.0
    private var wasLastTouchInside = true
    private var shouldUpdateValue = true
    
    private lazy var contentSizeObservation = scrollView.observe(\.contentSize, options: [.new]) { [weak self] (scrollView, change) in
        guard let self = self else { return }
        
        self.performWithoutUpdatingValue { self.updateScrollViewOffset() }
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
        backgroundColor = .clear
        
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(scrollViewPanAction(_:)))
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = true
        segmentReplicatorView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(segmentReplicatorView)
        addSubview(scrollView)
        scrollView.delegate = self
        
        NSLayoutConstraint.activate([
            segmentReplicatorView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            segmentReplicatorView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            segmentReplicatorView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            segmentReplicatorView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            segmentReplicatorView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            scrollView.centerXAnchor.constraint(equalTo: centerXAnchor),
            scrollView.centerYAnchor.constraint(equalTo: centerYAnchor),
            scrollView.widthAnchor.constraint(equalTo: widthAnchor),
            scrollView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
        
        indicatorLayer.mask = CALayer()
        indicatorLayer.contentsScale = UIScreen.main.scale
        indicatorLayer.mask?.contentsScale = UIScreen.main.scale
        indicatorLayer.backgroundColor = tintColor.cgColor
        layer.addSublayer(indicatorLayer)
        
        _ = contentSizeObservation
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        performWithoutUpdatingValue {
            let halfWidth = bounds.width / 2.0
            guard scrollView.contentInset.left != halfWidth else { return }
            
            scrollView.contentInset = UIEdgeInsets(top: 0.0, left: bounds.width / 2.0, bottom: 0.0, right: bounds.width / 2.0)
            updateScrollViewOffset()
        }
        
        updateIndiciatorLayer()
    }
    
    public override func tintColorDidChange() {
        indicatorLayer.backgroundColor = tintColor.cgColor
        
        super.tintColorDidChange()
    }
    
    private func updateIndiciatorLayer() {
        indicatorLayer.bounds = CGRect(x: 0.0, y: 0.0, width: separatorLineWidth, height: layer.bounds.height)
        indicatorLayer.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        indicatorLayer.mask?.frame = indicatorLayer.bounds
        
        let halfLineWidth = separatorLineWidth / 2.0
        let radius = halfLineWidth
        
        let segmentHeight = radius + 1.0 + radius + separatorLineHeightDifference
        
        indicatorLayer.mask?.contents = UIGraphicsImageRenderer(bounds: CGRect(x: 0.0, y: 0.0, width: separatorLineWidth, height: segmentHeight)).image { (context) in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0.0, y: 0.0, width: separatorLineWidth, height: segmentHeight), cornerRadius: CGFloat(radius)).fill()
        }.cgImage
        
        let y = (separatorLineHeightDifference / 2.0 + radius) / segmentHeight
        indicatorLayer.mask?.contentsCenter = CGRect(x: 0.0,
                                                     y: y,
                                                     width: 1.0,
                                                     height: 1.0 - 2 * y)
    }
    
    private func updateScrollViewOffset() {
        let offset = CGPoint(x: -scrollView.contentInset.left + (self.valueProgress * scrollView.contentSize.width), y: 0.0)
        
//        os_log("Setting: %@", type: .debug, "\(offset)")
        
        scrollView.contentOffset = offset
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
//        os_log("Setted: %@", type: .debug, "\(scrollView.contentOffset)") // BUG: the value doesn't match with the setted one.
        let progress = Double((scrollView.contentOffset.x + scrollView.contentInset.left) / scrollView.contentSize.width)
//        os_log("Progress: %@", type: .debug, "\(progress)")
        
        guard shouldUpdateValue else { return }
        
        let newValue = minimumValue + min(1.0, max(0.0, progress)) * (maximumValue - minimumValue)
        guard newValue != actualValue else { return }
        actualValue = newValue
        sendActions(for: [.valueChanged])
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) { isDecelerating = true }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { isDecelerating = false }
}
