# Tile Render

Tilerender - a simple graphics interface to display colorized squares on command line or via sockets.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     tilerender:
       github: SlayerShadow/tilerender
   ```

2. Run `shards install`

## Usage

_Please note that all input is buffered and method `flush` should be called to draw the output._

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

   ```crystal
   require "tilerender/interfaces/tcp"
   interface = Tilerender::TCP.new
   ```

Basic usage:

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

1. Clone it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Merge Request

## Contributors

- [SlayerShadow](https://github.com/SlayerShadow) - creator and maintainer
