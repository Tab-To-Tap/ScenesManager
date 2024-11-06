//
//  ImmersiveSpaceTrackerModifier.swift
//  ScenesManager
//
//  Created by Tom Krikorian on 02/11/2024.
//

import SwiftUI

/// A modifier that tracks the lifecycle of an immersive space.
///
/// Use `ImmersiveSpaceTrackerModifier` to:
/// - Track immersive space appearance and disappearance
/// - Update immersive space state in the `ScenesManager`
/// - Note: The `inTransition` state is handled by the ScenesManager's toggleImmersiveSpace method
///
/// ## Example
/// ```swift
/// struct ImmersiveView: View {
///     var body: some View {
///         RealityView { content in
///             // RealityKit content
///         }
///         .immersiveSpaceTracker()
///     }
/// }
/// ```
private struct ImmersiveSpaceTrackerModifier: ViewModifier {
    @Environment(\.scenesManager) private var scenesManager
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                scenesManager.immersiveSpaceState = .open
            }
            .onDisappear {
                scenesManager.immersiveSpaceState = .closed
            }
    }
}

public extension View {
    /// Adds immersive space state tracking to a view.
    ///
    /// Use this modifier in your immersive space views to automatically update
    /// the immersive space state in the `ScenesManager`.
    ///
    /// - Returns: A view that updates the immersive space state
    ///
    /// ## Example
    /// ```swift
    /// struct ImmersiveView: View {
    ///     var body: some View {
    ///         RealityView { content in
    ///             // RealityKit content
    ///         }
    ///         .immersiveSpaceTracker()
    ///     }
    /// }
    /// ```
    func immersiveSpaceTracker() -> some View {
        modifier(ImmersiveSpaceTrackerModifier())
    }
}
