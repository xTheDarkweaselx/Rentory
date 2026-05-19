//
//  RentoryWatchComplicationsBundle.swift  (RentoryWatchComplications)
//  Rentory
//
//  WidgetBundle @main entry for the watchOS complications extension.
//  Add new complications by appending them to body — they'll appear
//  in the watch face complication picker automatically.
//

import SwiftUI
import WidgetKit

@main
struct RentoryWatchComplicationsBundle: WidgetBundle {
    var body: some Widget {
        NextReminderComplication()
        PropertyCompletionComplication()
    }
}
