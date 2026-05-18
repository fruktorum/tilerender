# TileRender — Agent Notes

## Project
Crystal shard (library) for rendering colorized tile grids via CLI or TCP socket.
Crystal **1.20.2**. No external shard dependencies.

## Commands
```
shards install          # install deps (none currently, but required by workflow)
crystal spec            # run all tests
crystal tool format     # format code (2-space indent, enforced by CI)
crystal tool format --check  # CI format check
```
CI order: format check → spec (`.travis.yml`).

## Architecture
See `project-map.md` for full file tree and require boundaries.

```
src/
  tilerender.cr          # main entry — requires color, interfaces/base, version
  color.cr               # Color enum (17 named + Empty = 18 total) + RGBColor record + BaseColor alias
  version.cr             # shard version
  interfaces/
    base.cr              # abstract class Tilerender::Base (defines public API)
    command_line.cr      # CLI renderer (buffered — must call flush)
    tcp.cr               # TCP server renderer (unbuffered, port from ENV INTERFACE_PORT or arg; also provides toggle_lines, close_connection)
```

## Key quirks
- **CLI interface is buffered**: `reset` and `clear` print immediately; wrap with `hide`/`show` to suppress.
- **TCP interface is unbuffered**: `flush` re-sends all buffered background commands (has TODO for proper buffering).
- `dimensions` takes `UInt16` (not Int). Colors accept `Color` enum or individual RGB components (`UInt8`).
- `foreground` overrides `background` on a tile; `reset` clears both, `clear` clears foreground only.

## Testing
- `crystal spec` runs `spec/command_line_spec.cr` and `spec/tcp_spec.cr`.
- No special services needed; TCP spec binds to a local port.
- `spec/spec_helper.cr` only requires `spec` and `../src/tilerender`.

## Docker dev
```
docker-compose run --rm --service-ports dev
```
Exposes port 3248, joins external network `websockify-proxy`.

## Style
2-space indent, LF line endings, trailing newline (`.editorconfig`). Follow Crystal formatter.
