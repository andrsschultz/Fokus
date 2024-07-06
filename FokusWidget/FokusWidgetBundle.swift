//
//  FokusWidgetBundle.swift
//  FokusWidget
//
//  Created by Andreas Schultz on 20.12.23.
//

import WidgetKit
import SwiftUI

@main
struct FokusWidgetBundle: WidgetBundle {
    var body: some Widget {
        FokusWidget()
        FokusWidgetLiveActivity()
    }
}
