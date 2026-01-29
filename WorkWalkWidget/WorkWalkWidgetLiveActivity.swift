//
//  WorkWalkWidgetLiveActivity.swift
//  WorkWalkWidget
//
//  Created by Alan Krieger on 27/01/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WorkWalkWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WorkWalkWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkWalkWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WorkWalkWidgetAttributes {
    fileprivate static var preview: WorkWalkWidgetAttributes {
        WorkWalkWidgetAttributes(name: "World")
    }
}

extension WorkWalkWidgetAttributes.ContentState {
    fileprivate static var smiley: WorkWalkWidgetAttributes.ContentState {
        WorkWalkWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WorkWalkWidgetAttributes.ContentState {
         WorkWalkWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WorkWalkWidgetAttributes.preview) {
   WorkWalkWidgetLiveActivity()
} contentStates: {
    WorkWalkWidgetAttributes.ContentState.smiley
    WorkWalkWidgetAttributes.ContentState.starEyes
}
