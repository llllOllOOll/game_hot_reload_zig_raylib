# Zig Hot Reload Game Engine

A modular 2D game engine in Zig demonstrating clean architecture, layer separation, and hot-reload capabilities using C library integration.

## Core Architecture Principles

This project showcases modern Zig software architecture with:

- **Layer Separation**: Clear boundaries between engine, platform, and game logic
- **Modular Design**: Each component is a self-contained module with well-defined interfaces
- **Hot Reload**: Dynamic library loading for live code updates without application restart
- **C Library Integration**: Direct use of libc functions (dlfcn) for dynamic loading
- **Dependency Injection**: Platform abstraction allows for easy testing and portability

## Features

- **Hot Reload**: Modify game code and see changes without restarting the application
- **Layered Architecture**: Engine → Platform → Game separation
- **C Library Integration**: Direct libc usage for system-level operations
- **WASD Movement**: Player character with keyboard controls
- **Jump Mechanics**: Basic physics with gravity
- **Raylib Integration**: Uses zraylib for rendering and input

## Project Structure

```
zig_modules/
├── build.zig              # Build configuration
├── src/
│   ├── main.zig           # Main executable with hot-reload system
│   ├── platform/          # Platform abstraction layer
│   │   ├── root.zig       # Platform module definition
│   │   ├── renderer.zig   # Rendering interface
│   │   ├── window.zig     # Window management
│   │   └── render_command.zig # Rendering commands
│   └── game/              # Hot-reloadable game code
│       └── root.zig       # Game logic and update functions
└── README.md
```

## Building and Running

### Prerequisites

- Zig 0.16.0-dev.2261+d6b3dd25a or later
- Raylib development libraries
- Linux (currently tested on Linux)

### Build Commands

```bash
# Build the entire project
zig build

# Run the game
zig build run

# Build only the game library (for fast iteration)
zig build game

# Watch for changes and auto-rebuild (experimental)
zig build watch
```

### Development Workflow

1. Run the game: `zig build run`
2. Modify game logic in `src/game/root.zig`
3. In another terminal, rebuild the game library: `zig build game`
4. The running game will automatically hot-reload with your changes

## Game Controls

- **W**: Jump
- **A**: Move left
- **S**: Move down
- **D**: Move right

## Architecture

### Layer Separation

The project follows a strict layered architecture:

1. **Engine Layer** (`src/main.zig`): Application entry point, hot-reload manager, memory management
2. **Platform Layer** (`src/platform/`): Hardware abstraction for graphics, input, and windowing
3. **Game Layer** (`src/game/`): Application-specific game logic and rendering

### Hot Reload System

The engine uses C library integration for dynamic loading:

- **dlopen/dlsym**: Direct libc functions for loading game library symbols
- **Memory Persistence**: Game state preserved across library reloads
- **Timestamp Monitoring**: File modification detection for automatic reloading
- **Error Handling**: Graceful fallback if hot reload fails

### Module Design

Each layer is a separate Zig module with clear interfaces:

- **Platform Module**: Abstracts Raylib behind a clean API
- **Game Library**: Self-contained logic as a dynamic library (.so)
- **Renderer Interface**: Command-based rendering system

### Key Components

- **GameCode**: Handles loading/unloading of the game library using libc
- **GameState**: Persistent game state across reloads
- **Platform Renderer**: Abstract rendering interface using Raylib
- **Memory Management**: Pre-allocated shared memory for hot-reload persistence

### Export Functions

The game library exports these functions:

```zig
// Called every frame for game logic and rendering
pub export fn game_update(
    memory_ptr: [*]u8,
    memory_size: usize,
    window_width: f32,
    window_height: f32,
    renderer: *Platform.Renderer,
) callconv(.c) void;

// Called when the library is hot-reloaded
pub export fn game_on_reload(
    memory_ptr: [*]u8,
    memory_size: usize,
) callconv(.c) void;
```

## Development Tips

- The game state is preserved during hot reloads
- Use `game_on_reload` to restore or reinitialize resources
- Console output shows hot-reload debugging information
- Only the game library needs to be rebuilt during development

## Dependencies

- **zraylib**: Zig bindings for Raylib (rendering & input)
- **libc**: Direct C library integration (dlfcn for dynamic loading)
- **System Libraries**: libdl for dynamic library operations

## Zig Version Compatibility

This project uses **Zig 0.16.0-dev.2261+d6b3dd25a** and demonstrates:
- Modern module system usage
- C library integration patterns
- Advanced build system configuration
- Memory management best practices

## License

This project is provided as a learning example for hot-reload game development in Zig.
