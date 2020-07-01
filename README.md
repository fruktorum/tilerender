# Tile Render

Tilerender - a simple graphics interface. It supports two different interfaces: command-line and sockets.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     tilerender:
       github: SlayerShadow/tilerender
   ```

2. Run `shards install`

## Usage

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
interface.background 0, 0, Tilerender::Color::Red # Fill background color of tile (x: 0, y: 0) with Red color
interface.foreground 1, 0, Tilerender::Color::Blue # Fill foreground color of tile (x: 1, y: 0) with Blue color
interface.flush # Render to output
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

TODO: Make available full RGB palette

## Development

`docker-compose run --rm --service-ports dev` - launch dev Crystal environment

## Contributing

1. Clone it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Merge Request

## Contributors

- [SlayerShadow](https://github.com/SlayerShadow) - creator and maintainer
