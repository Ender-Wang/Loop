//
//  PreviewView.swift
//  Loop
//
//  Created by Kai Azim on 2023-01-24.
//

import SwiftUI
import Defaults

struct PreviewView: View {

    @State var currentAction: WindowAction
    private let window: Window?
    private let previewMode: Bool

    init(
        previewMode: Bool = false,
        window: Window?,
        startingAction: WindowAction = .init(.noAction)
    ) {
        self.window = window
        self.previewMode = previewMode
        self._currentAction = State(initialValue: startingAction)
    }

    @Default(.useSystemAccentColor) var useSystemAccentColor
    @Default(.customAccentColor) var customAccentColor
    @Default(.useGradient) var useGradient
    @Default(.gradientColor) var gradientColor

    @Default(.previewVisibility) var previewVisibility
    @Default(.previewPadding) var previewPadding
    @Default(.windowPadding) var windowPadding
    @Default(.previewCornerRadius) var previewCornerRadius
    @Default(.previewBorderThickness) var previewBorderThickness
    @Default(.animationConfiguration) var animationConfiguration

    @Default(.respectStageManager) var respectStageManager
    @Default(.stageStripSize) var stageStripSize

    var body: some View {
        HStack(spacing: 0) {
            if respectStageManager &&
                StageManager.enabled &&
                StageManager.shown &&
                StageManager.position == .leading {
                Spacer()
                    .frame(width: stageStripSize)
            }

            GeometryReader { geo in
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                        .mask(RoundedRectangle(cornerRadius: previewCornerRadius).foregroundColor(.white))
                        .shadow(radius: 10)
                    RoundedRectangle(cornerRadius: previewCornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        Color.getLoopAccent(tone: .normal),
                                        Color.getLoopAccent(tone: useGradient ? .darker : .normal)
                                    ]
                                ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: previewBorderThickness
                        )
                }
                .padding(windowPadding + previewPadding + previewBorderThickness / 2)

                .frame(
                    width: self.currentAction.previewWindowWidth(geo.size.width, window),
                    height: self.currentAction.previewWindowHeight(geo.size.height, window)
                )

                .offset(
                    x: self.currentAction.previewWindowXOffset(geo.size.width, window),
                    y: self.currentAction.previewWindowYOffset(geo.size.height, window)
                )

                if respectStageManager &&
                    StageManager.enabled &&
                    StageManager.shown &&
                    StageManager.position == .trailing {
                    Spacer()
                        .frame(width: stageStripSize)
                }
            }
        }
        .opacity(currentAction.direction == .noAction ? 0 : 1)
        .animation(animationConfiguration.previewWindowAnimation, value: currentAction)
        .onReceive(.directionChanged) { obj in
            if !self.previewMode,
               let action = obj.userInfo?["action"] as? WindowAction,
               !action.direction.isPresetCyclable,
               action.direction != .cycle {

                self.currentAction = action

                if self.currentAction.direction == .undo && self.window != nil {
                    self.currentAction = WindowRecords.getLastAction(for: self.window!)
                }
            }
        }
        .onAppear {
            if self.previewMode {
                self.currentAction = .init(.maximize)
            }
        }
    }
}
