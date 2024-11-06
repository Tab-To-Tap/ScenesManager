//
//  SceneTrackerModifier.swift
//  ScenesManager
//
//  Created by Tom Krikorian on 02/11/2024.
//

import SwiftUI
import OSLog

/// A modifier that tracks the lifecycle of a scene and manages its visibility state.
///
/// Use `SceneTrackerModifier` to:
/// - Track scene activation and deactivation
/// - Handle scene lifecycle callbacks
/// - Manage scene state transitions (opening, opened, closing, closed)
/// - Automatically update scene states in the ScenesManager
///
/// ## Example
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         ContentView()
///             .sceneTracker(for: .mainWindow, 
///                 onOpen: { print("Scene opened") },
///                 onDismiss: { print("Scene dismissed") }
///             )
///     }
/// }
/// ```
private struct SceneTrackerModifier: ViewModifier {
    /// The scene identifier to track
    let trackedScene: SceneId
    
    @Environment(\.scenesManager) private var scenesManager
    @Environment(\.scenePhase) private var scenePhase
    
    /// Callback triggered when the scene becomes active
    var onOpen: (() -> Void)?
    
    /// Callback triggered when the scene is dismissed
    var onDismiss: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase, initial: true) {
                switch scenePhase {
                case .active:
                    Logger.scenesManager.info("SceneTrackerModifier: scenePhase \(trackedScene.rawValue) is active - setting state to opened")
                    scenesManager.setSceneState(.opened, for: trackedScene)
                    self.trackSceneActivation()
                case .background:
                    Logger.scenesManager.info("SceneTrackerModifier: scenePhase \(trackedScene.rawValue) is background - setting state to closed")
                    scenesManager.setSceneState(.closed, for: trackedScene)
                    self.trackSceneDeactivation()
                case .inactive:
                    Logger.scenesManager.info("SceneTrackerModifier: scenePhase \(trackedScene.rawValue) is inactive")
                @unknown default:
                    Logger.scenesManager.error("SceneTrackerModifier: scenePhase unknown")
                }
            }
    }
    
    /// Handles scene activation and triggers the onOpen callback if needed
    private func trackSceneActivation() {
        if !scenesManager.areEventsSuppressed(.openEvent, for: trackedScene) {
            onOpen?()
        }
    }
    
    /// Handles scene deactivation and triggers the onDismiss callback if needed
    private func trackSceneDeactivation() {
        if !scenesManager.areEventsSuppressed(.dismissEvent, for: trackedScene) {
            onDismiss?()
        }
    }
}

public extension View {
    /// Adds scene lifecycle tracking to a view.
    ///
    /// Use this modifier to track when a scene becomes active or is dismissed.
    ///
    /// - Parameters:
    ///   - trackedScene: The scene identifier to track
    ///   - onOpen: Optional callback triggered when the scene becomes active
    ///   - onDismiss: Optional callback triggered when the scene is dismissed
    ///
    /// - Returns: A view with scene tracking capabilities
    ///
    /// ## Example
    /// ```swift
    /// ContentView()
    ///     .sceneTracker(for: .mainWindow) {
    ///         print("Window opened")
    ///     } onDismiss: {
    ///         print("Window dismissed")
    ///     }
    /// ```
    func sceneTracker(for trackedScene: SceneId, onOpen: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(SceneTrackerModifier(trackedScene: trackedScene, onOpen: onOpen, onDismiss: onDismiss))
    }
}
