//
//  SceneId.swift
//  ScenesManager
//
//  Created by Tom Krikorian on 02/11/2024.
//

/// A type-safe identifier for scenes in a visionOS app.
///
/// Use `SceneId` to uniquely identify and manage windows and immersive spaces in your app.
/// You can create custom scene identifiers by extending this type.
///
/// ## Topics
///
/// ### Creating Scene Identifiers
/// ```swift
/// extension SceneId {
///     static var settings: Self { .init(rawValue: "Settings") }
///     static var mainWindow: Self { .init(rawValue: "MainWindow") }
/// }
/// ```
///
/// ### Using Scene Identifiers
/// ```swift
/// WindowGroup(id: SceneId.settings.rawValue) {
///     SettingsView()
///         .sceneTracker(for: .settings)
/// }
/// ```
public struct SceneId: RawRepresentable, Hashable {
    /// The string value that uniquely identifies the scene.
    ///
    /// This value is used internally to track and manage scenes within the app.
    public var rawValue: String
    
    /// Creates a new scene identifier.
    ///
    /// - Parameter rawValue: A unique string identifier for the scene
    /// - Returns: A new scene identifier instance
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - Built-in Scene Identifiers
public extension SceneId {
    /// The identifier for the immersive space scene.
    ///
    /// This identifier is used internally by the `ScenesManager` to track
    /// and manage the immersive space state.
    static var immersiveSpace: Self { .init(rawValue: "ImmersiveSpace") }
}
