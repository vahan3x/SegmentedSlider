//
//  ViewController.swift
//  Sample
//
//  Created by Vahan Babayan on 9/1/18.
//  Copyright © 2018 vahan3x. All rights reserved.
//

import UIKit
import SegmentedSlider

class ViewController: UIViewController {
    
    // MARK: - Variables
    
    @IBOutlet private weak var segmentedSlider: SegmentedSlider!
    @IBOutlet private weak var stepper: UIStepper!
    @IBOutlet private weak var label: UILabel!
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Actions
    
    @IBAction private func stepperAction(_ sender: UIStepper) {
        segmentedSlider.value = sender.value
    }
    
    @IBAction func sliderAction(_ sender: SegmentedSlider) {
        stepper.value = sender.value
        label.text = "\(sender.value)"
        print("Slider Value changed: \(sender.value)")
    }
}

