//
//  ScenesManager.swift
//  ScenesManager
//
//  Created by Tom Krikorian and Tina Debove Nigro
//

import Foundation
import SwiftUI
import OSLog

/// A manager class that handles window and immersive space scenes in a visionOS app.
///
/// The `ScenesManager` provides centralized control over:
/// - Scene visibility tracking
/// - Window state management (opening, opened, closing, closed)
/// - Window and immersive space lifecycle
/// - Event suppression and handling
///
/// ## Scene States
/// Windows can transition through different states:
/// ```swift
/// // Check scene state
/// let state = scenesManager.getSceneState(for: .settings)
/// switch state {
/// case .opening:  // Scene is being opened
/// case .opened:   // Scene is active
/// case .closing:  // Scene is being dismissed
/// case .closed:   // Scene is not visible
/// }
/// ```
///
/// ## Scene Events
/// The manager supports suppressing different types of scene events:
/// - Opening events: Prevents windows from being opened
/// - Dismissal events: Prevents windows from being dismissed
///
/// ## Example Usage
/// ```swift
/// // Basic setup in your app
/// @Environment(\.scenesManager) var scenesManager
///
/// // Open a window
/// scenesManager.openWindow(.settings)
///
/// // Toggle immersive space
/// await scenesManager.toggleImmersiveSpace()
///
/// // Suppress both open and dismiss events
/// scenesManager.suppressEvents(for: .settings)
///
/// // Suppress specific events
/// scenesManager.suppressEvents([.openEvent, .dismissEvent], for: .settings)
///
/// // Remove suppression
/// scenesManager.unsuppressEvents(for: .settings)
/// ```
@Observable public final class ScenesManager {

    private var openWindow: OpenWindowAction?
    private var dismissWindow: DismissWindowAction?
    private var openImmersiveSpace: OpenImmersiveSpaceAction?
    private var dismissImmersiveSpace: DismissImmersiveSpaceAction?
    
    /// Represents the current state of the immersive space.
    public enum ImmersiveSpaceState {
        /// The immersive space is not visible
        case closed
        /// The immersive space is currently transitioning between states
        case inTransition
        /// The immersive space is visible
        case open
    }
    
    /// The current state of the immersive space.
    public var immersiveSpaceState = ImmersiveSpaceState.closed

    /// Creates a new scenes manager instance.
    ///
    /// - Returns: A new `ScenesManager` instance configured for use in a visionOS app.
    public init() { }

    /// Configures the environment actions used by the scenes manager.
    ///
    /// - Parameters:
    ///   - openWindow: The SwiftUI action to open windows
    ///   - dismissWindow: The SwiftUI action to dismiss windows
    ///   - openImmersiveSpace: The SwiftUI action to open immersive spaces
    ///   - dismissImmersiveSpace: The SwiftUI action to dismiss immersive spaces
    ///
    /// - Note: Call this method early in your app's lifecycle, typically in the main app scene.
    public func setActions(
        openWindow: OpenWindowAction,
        dismissWindow: DismissWindowAction,
        openImmersiveSpace: OpenImmersiveSpaceAction,
        dismissImmersiveSpace: DismissImmersiveSpaceAction
    ) {
        self.openWindow = openWindow
        self.dismissWindow = dismissWindow
        self.openImmersiveSpace = openImmersiveSpace
        self.dismissImmersiveSpace = dismissImmersiveSpace
    }
    
    /// Represents the current state of a window
    public enum SceneState {
        /// The window is in the process of opening
        case opening
        /// The window is open and active
        case opened
        /// The window is in the process of closing.
        case closing
        /// The window is closed but still being tracked
        case closed
    }
    
    /// Currently tracked scene states, automatically updated by scene trackers.
    private var sceneStates: [SceneId: SceneState] = [:]

    /// Gets the current state of a window.
    ///
    /// - Parameter scene: The scene identifier to check
    /// - Returns: The current `SceneState` of the scene, or `.closed` if not tracked
    public func getSceneState(for scene: SceneId) -> SceneState {
        sceneStates[scene] ?? .closed
    }

    /// Sets the state of a window.
    ///
    /// - Parameters:
    ///   - state: The new window state to set
    ///   - scene: The scene identifier to update
    public func setSceneState(_ state: SceneState, for scene: SceneId) {
        sceneStates[scene] = state
    }
    
    /// Defines which events can be suppressed for a scene.
    ///
    /// Use this type to control which events should be prevented from occurring:
    /// ```swift
    /// // Suppress multiple events
    /// scenesManager.suppressEvents([.openEvent, .dismissEvent], for: .settings)
    ///
    /// // Check if events are suppressed
    /// if scenesManager.areEventsSuppressed(.dismissEvent, for: .settings) {
    ///     print("Dismiss events are suppressed")
    /// }
    /// ```
    public struct SceneEventMask: OptionSet, Sendable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        /// Suppresses the scene's dismiss event, preventing window dismissal
        public static let dismissEvent = SceneEventMask(rawValue: 1 << 0)
        
        /// Suppresses the scene's open event, preventing window opening
        public static let openEvent = SceneEventMask(rawValue: 1 << 1)
        
        /// Suppresses all events for the scene
        public static let all: SceneEventMask = [.dismissEvent, .openEvent]
    }
    
    /// Tracks which events are suppressed for each scene
    private var suppressedEvents: [SceneId: SceneEventMask] = [:]
    
    /// Suppresses specific events for a scene.
    ///
    /// Use this method to prevent certain scene events from occurring. This is useful
    /// when you want to temporarily disable window opening or dismissal.
    ///
    /// - Parameters:
    ///   - events: The events to suppress (e.g., `.dismissEvent`, `.openEvent`, or `.all`)
    ///   - scene: The scene identifier to suppress events for
    ///
    /// ## Example
    /// ```swift
    /// // Suppress both open and dismiss events
    /// scenesManager.suppressEvents(.all, for: .settings)
    ///
    /// // Suppress only dismiss events
    /// scenesManager.suppressEvents(.dismissEvent, for: .settings)
    /// ```
    public func suppressEvents(_ events: SceneEventMask, for scene: SceneId) {
        if var existing = suppressedEvents[scene] {
            existing.formUnion(events)
            suppressedEvents[scene] = existing
        } else {
            suppressedEvents[scene] = events
        }
    }
    
    /// Removes event suppression for a scene.
    ///
    /// Use this method to re-enable previously suppressed events.
    ///
    /// - Parameters:
    ///   - events: The events to unsuppress (defaults to `.all`)
    ///   - scene: The scene identifier to remove event suppression from
    ///
    /// ## Example
    /// ```swift
    /// // Remove all event suppression
    /// scenesManager.unsuppressEvents(for: .settings)
    ///
    /// // Remove only open event suppression
    /// scenesManager.unsuppressEvents(.openEvent, for: .settings)
    /// ```
    public func unsuppressEvents(_ events: SceneEventMask = .all, for scene: SceneId) {
        guard var existing = suppressedEvents[scene] else { return }
        existing.subtract(events)
        if existing.isEmpty {
            suppressedEvents.removeValue(forKey: scene)
        } else {
            suppressedEvents[scene] = existing
        }
    }

    /// Checks if specific events are suppressed for a scene.
    ///
    /// - Parameters:
    ///   - events: The events to check
    ///   - scene: The scene identifier to check
    /// - Returns: `true` if all specified events are suppressed for the scene
    ///
    /// ## Example
    /// ```swift
    /// if scenesManager.areEventsSuppressed(.dismissEvent, for: .settings) {
    ///     print("Cannot dismiss settings window")
    /// }
    /// ```
    public func areEventsSuppressed(_ events: SceneEventMask, for scene: SceneId) -> Bool {
        guard let suppressed = suppressedEvents[scene] else { return false }
        return suppressed.intersection(events) == events
    }
    
    /// Opens a window with the specified scene identifier.
    ///
    /// - Parameter scene: The scene identifier for the window to open
    /// - Note: This method checks the current window state and handles transitions appropriately
    @MainActor
    public func openWindow(_ scene: SceneId) {
        guard let openWindow = openWindow else { return }
        
        // Check if we can open this window
        if let state = sceneStates[scene] {
            switch state {
            case .closed, .closing:
                Logger.scenesManager.info("Opening window for scene \(scene.rawValue) with state opening")
                sceneStates[scene] = .opening
                openWindow(id: scene.rawValue)
            case .opening, .opened:
                Logger.scenesManager.info("Window for scene \(scene.rawValue) is already open or opening")
            }
        } else {
            Logger.scenesManager.info("First time tracking window for scene \(scene.rawValue) with state opening")
            sceneStates[scene] = .opening
            openWindow(id: scene.rawValue)
        }
    }
    
    /// Dismisses a window with the specified scene identifier.
    ///
    /// - Parameter scene: The scene identifier for the window to dismiss
    /// - Note: This method updates the window state to `.closing` before dismissal
    @MainActor
    public func dismissWindow(_ scene: SceneId) {
        guard let dismissWindow = dismissWindow else { return }
        Logger.scenesManager.info("Dismissing window for scene \(scene.rawValue) with state closing")
        sceneStates[scene] = .closing
        dismissWindow(id: scene.rawValue)
    }
    
    /// Toggles the immersive space between open and closed states.
    ///
    /// - Note: This method handles state transitions and error cases automatically
    /// - Returns: An async task that completes when the toggle operation is finished
    @MainActor
    public func toggleImmersiveSpace() async {
        guard let dismissImmersiveSpace = dismissImmersiveSpace,
              let openImmersiveSpace = openImmersiveSpace else { return }
        
        switch immersiveSpaceState {
        case .open:
            sceneStates[SceneId.immersiveSpace] = .closing
            immersiveSpaceState = .inTransition
            await dismissImmersiveSpace()
        case .closed:
            sceneStates[SceneId.immersiveSpace] = .opening
            immersiveSpaceState = .inTransition
            switch await openImmersiveSpace(id: SceneId.immersiveSpace.rawValue) {
            case .opened:
                break
            case .userCancelled, .error:
                Logger.scenesManager.error("Failed to open immersive space. Did you you setup the immersive space correctly with SceneId.immersiveSpace?")
                immersiveSpaceState = .closed
                sceneStates[SceneId.immersiveSpace] = .closed
            @unknown default:
                immersiveSpaceState = .closed
                sceneStates[SceneId.immersiveSpace] = .closed
            }
        case .inTransition:
            break
        }
    }
}

/// Provides access to the scenes manager through the SwiftUI environment.
public extension EnvironmentValues {
    /// The scenes manager instance for the current environment.
    @Entry var scenesManager: ScenesManager = .init()
}
