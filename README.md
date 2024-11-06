# ScenesManager

A SwiftUI package for managing windows and immersive spaces in visionOS applications. ScenesManager provides centralized control over scene lifecycle, visibility tracking, and event handling.

## Authors

Created by [Tom Krikorian](https://github.com/tomkrikorian) and [Tina Debove Nigro](https://github.com/tinanigro)

Inspired by [VisibilityTrackerModifier](https://gist.github.com/florentmorin/a462293c9db7f74092aa8775a056398a) from [Florent Morin](https://github.com/florentmorin)

## Features

- Track window and immersive space visibility
- Manage scene lifecycle events
- Suppress window opening and dismissal events
- Simple SwiftUI modifiers for scene tracking
- Immersive space state management

## Installation

Add ScenesManager to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/Tab-To-Tap/ScenesManager.git", from: "1.0.0")
]
```

## Quick Start

1. Set up the ScenesManager in your main app scene:

```swift
@main
struct MyApp: App {
    @Environment(\.openWindow) var openWindow   
    @Environment(\.dismissWindow) var dismissWindow
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    @State private var scenesManager = ScenesManager()

    var body: some Scene {
        WindowGroup(id: SceneId.mainWindow.rawValue) {
            ContentView()
                .environment(\.scenesManager, scenesManager)
                .onAppear {
                    scenesManager.setActions(
                        openWindow: openWindow,
                        dismissWindow: dismissWindow,
                        openImmersiveSpace: openImmersiveSpace,
                        dismissImmersiveSpace: dismissImmersiveSpace
                    )
                }
        }
    }
}
```

2. Track window lifecycle using the scene tracker modifier:

```swift
struct MyView: View {
    var body: some View {
        ContentView()
            .sceneTracker(for: .mainWindow, 
                onOpen: { print("Window opened") },
                onDismiss: { print("Window dismissed") }
            )
    }
}
```

3. Track immersive spaces:

```swift
struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            // Your RealityKit content
        }
        .immersiveSpaceTracker()
    }
}
```

## Defining Scene Identifiers

Before using ScenesManager, you need to define your scene identifiers. Create an extension of `SceneId` in your app:

```swift
import ScenesManager

public extension SceneId {
    static var mainWindow: Self { .init(rawValue: "MainWindow") }
    static var settings: Self { .init(rawValue: "Settings") }
    static var immersiveMenu: Self { .init(rawValue: "ImmersiveMenu") }
}
```

The package already includes the `immersiveSpace` identifier that's used internally:

```swift
public extension SceneId {
    /// The identifier for the immersive space scene
    static var immersiveSpace: Self { .init(rawValue: "ImmersiveSpace") }
}
```

### Using Scene Identifiers

Once defined, you can use these identifiers throughout your app:

```swift
// In your WindowGroup declarations
WindowGroup(id: SceneId.mainWindow.rawValue) {
    ContentView()
}

// When opening windows
scenesManager.openWindow(.settings)

// When tracking scenes
.sceneTracker(for: .mainWindow)

// For immersive spaces
ImmersiveSpace(id: SceneId.immersiveSpace.rawValue) {
    ImmersiveView()
}
```

## Usage

### Managing Windows

```swift
@Environment(\.scenesManager) var scenesManager

// Open a window
scenesManager.openWindow(.settings)

// Dismiss a window
scenesManager.dismissWindow(.settings)
```

### Event Suppression

```swift
// Suppress both open and dismiss events
scenesManager.suppressEvents(.all, for: .settings)

// Suppress only dismiss events
scenesManager.suppressEvents(.dismissEvent, for: .settings)

// Remove suppression
scenesManager.unsuppressEvents(for: .settings)

// Check if events are suppressed
if scenesManager.areEventsSuppressed(.dismissEvent, for: .settings) {
    print("Cannot dismiss settings window")
}
```

### Immersive Space Management

```swift
// Toggle immersive space
await scenesManager.toggleImmersiveSpace()

// Check immersive space state
switch scenesManager.immersiveSpaceState {
case .open:
    print("Immersive space is visible")
case .closed:
    print("Immersive space is closed")
case .inTransition:
    print("Immersive space is transitioning")
}
```

### Scene State Management

Scenes can be in one of four states:
- `.opening`: Scene is in the process of opening
- `.opened`: Scene is fully open and active
- `.closing`: Scene is in the process of closing
- `.closed`: Scene is fully closed

```swift
// Check scene state
let state = scenesManager.getSceneState(for: .settings)
if state == .opened {
    print("Settings scene is fully open")
}
```

## Requirements

- visionOS 2.0+
- Swift 5.9+
