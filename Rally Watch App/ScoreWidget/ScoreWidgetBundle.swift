//
//  ScoreWidgetBundle.swift
//  ScoreWidget
//
//  Created by Matt Gregg on 10/8/26.
//

import WidgetKit
import SwiftUI

@main
struct ScoreWidgetBundle: WidgetBundle {
    var body: some Widget {
        RallyWidget()
        ScoreWidgetControl()
    }
}
