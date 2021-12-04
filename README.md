# TileRender

Tilerender: a simple graphics interface to display colorized squares via command-line or sockets.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     tilerender:
       github: fruktorum/tilerender
   ```

2. Run `shards install`

## Usage

_Note: for command-line all input is buffered and method `flush` should be called to draw the output._

Core dependencies:

```crystal
require "tilerender"
```

* To use command-line interface:

   ```crystal
   require "tilerender/interfaces/command_line"
   interface = Tilerender::CommandLine.new
   ```

* To use TCP socket interface:

   There is websocket client to work with: please see [TileRender Client](https://github.com/fruktorum/tilerender-client).

   ```crystal
   require "tilerender/interfaces/tcp"
   interface = Tilerender::TCP.new port: 3248, wait_first_connection: true
   ```

   * `port` - a port where the TCP server will be launched (default: `ENV[ "INTERFACE_PORT" ]`)
   * `wait_first_connection` - if true, waits for the first connection and prevents rendering to the void (default: `true`)

### Basic usage:

```crystal
interface.dimensions 3_u16, 2_u16 # Set the field dimenstions to 3x2 (width x height)
interface.reset # Clear colors of the field

# It supports two variants of rendering:
# Via Color enum (see below):
interface.background 0, 0, Tilerender::Color::Red # Fill background color of tile (x: 0, y: 0) with Red color
interface.foreground 1, 0, Tilerender::Color::Blue # Fill foreground color of tile (x: 1, y: 0) with Blue color

# Via RGB color base:
interface.background 0, 0, 255, 0, 0 # Fill background color of tile (x: 0, y: 0) with Red color
interface.foreground 1, 0, 0, 255, 0 # Fill foreground color of tile (x: 1, y: 0) with Blue color

# Now draw it:
interface.flush # Render to output
```

It is possible to use symbols instead of enums (until Crystal itself changes something):

```crystal
interface.background 0, 0, :red # Fill background color of tile (x: 0, y: 0) with Red color
```

### Environment variables

`INTERFACE_PORT : Int32` - listener port (used only for TCP interface)

### Background vs Foreground

```crystal
# Colorize tile (x: 0, y: 0)
interface.foreground 0, 0, Tilerender::Color::Red # => Tile (0, 0) has Red color
# Clear field
interface.reset # => Tile (0, 0) has no color

# Colorize foreground tile (x: 0, y: 0)
interface.foreground 0, 0, Tilerender::Color::Blue # => Tile (0, 0) has Blue color
# Colorize background tile (x: 0, y: 0)
interface.background 0, 0, Tilerender::Color::Red # => Tile (0, 0) still has Blue color (foreground)
# Clear field
interface.reset # => Tile (0, 0) has Red (background) color
```

### Public interface

* `dimensions( width : UInt16, height : UInt16 ) : Void` - set grid dimensions to `width` horizontally and `height` vertically
* `background( x : UInt16, y : UInt16, color : Color ) : Void` - set background color of `(x, y)` to one of `Color`
* `background( x : UInt16, y : UInt16, red : UInt8, green : UInt8, blue : UInt8 ) : Void` - set background of `(x, y)` to the RGB color
* `foreground( x : UInt16, y : UInt16, color : Color ) : Void` - set foreground color of `(x, y)` to one of `Color`
* `foreground( x : UInt16, y : UInt16, red : UInt8, green : UInt8, blue : UInt8 ) : Void` - set foreground of `(x, y)` to the RGB color
* `empty( x : UInt16, y : UInt16 ) : Void` - clear the cell placed on `(x, y)` (if background is set, fills the cell by that color)
* `clear : Void` - clear field of foreground (if specific cell has background, it will be placed, else - the cell's color will be removed)
* `reset : Void` - reset all field (remove background and foreground for all cells)
* `flush : Void` - print buffer to output (or write it to socket if TCP tilerender is in use) (currently TCP variant is unbuffered)
* `hide : Void` - disable output (calling `flush` resets buffer, even if it should not display something)
* `show : Void` - enable output
* `visible : Bool` - returns `true` if output should be rendered (if `hide` was not called) (default: `true`)

Commands `reset` and `clear` for command-line renderer prints result immediately. To prevent this please hide Tilerender with `hide`.

### Supported colors

`Tilerender::Color` is the `enum` that supports restricted amount of colors:

* Black
* Blue
* Cyan
* Gray
* Green
* Lime
* Magenta
* Maroon
* Navy
* Orange
* Pink
* Purple
* Red
* Silver
* Teal
* White
* Yellow

## Development

It is recommended to use Docker and latest Crystal language compilation.

1. `cp Dockerfile.sample Dockerfile`
2. Change 1st line in Dockerfile to actual Crystal image
3. `docker-compose run --rm --service-ports dev` - launch dev Crystal environment

## Contributing

1. Fork it (<https://github.com/fruktorum/tilerender/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Merge Request

## Contributors

- [SlayerShadow](https://github.com/SlayerShadow) - creator and maintainer
