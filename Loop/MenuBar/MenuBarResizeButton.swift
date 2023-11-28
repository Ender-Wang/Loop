//
//  MenuBarResizeButton.swift
//  Loop
//
//  Created by Kai Azim on 2023-09-30.
//

import SwiftUI

struct MenuBarResizeButton: View {
    let direction: WindowDirection

    init(_ direction: WindowDirection) {
        self.direction = direction
    }

    var body: some View {
        Button {
            if let frontmostWindow = WindowEngine.frontmostWindow,
               let screen = NSScreen.screenWithMouse {
                WindowEngine.resize(frontmostWindow, to: direction, screen)
            }
        } label: {
            HStack {
                if let image = direction.icon {
                    image
                    Text(direction.name)
                }
            }
        }
    }
}
