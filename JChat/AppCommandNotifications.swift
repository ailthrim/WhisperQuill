//
//  AppCommandNotifications.swift
//  JChat
//

import Foundation

enum AppCommandNotification {
    static let openSettings = Notification.Name("JChatOpenSettings")
    static let newChat = Notification.Name("JChatNewChat")
    static let deleteSelectedChat = Notification.Name("JChatDeleteSelectedChat")
    static let textZoomIn = Notification.Name("JChatTextZoomIn")
    static let textZoomOut = Notification.Name("JChatTextZoomOut")
    static let textZoomReset = Notification.Name("JChatTextZoomReset")
}
