# TileRender — Project Map

## Root files
```
tilerender/
├── .dockerignore          # Docker build exclusions
├── .editorconfig          # 2-space indent, LF, trailing newline, trim whitespace
├── .gitignore             # /bin/, /docs/, /lib/, /.shards/, shard.lock, test.cr, core, Thumbs.db, *.dwarf, .DS_Store
├── .travis.yml            # CI: format check → crystal spec
├── docker-compose.yml     # dev service, port 3248, external network websockify-proxy
├── Dockerfile             # crystallang/crystal:1.20.2-alpine
├── LICENSE                # MIT
├── README.md              # Usage docs, public API, color list
├── shard.yml              # name, version 1.1.1, crystal 1.20.2, no deps
├── spec/                  # test suite
└── src/                   # library source
```

## Source (`src/`)
```
src/
├── tilerender.cr          # Main entry point — requires color, interfaces/base, version
├── color.cr               # Color enum (17 named + Empty), RGBColor record, BaseColor alias
├── version.cr             # VERSION constant
└── interfaces/
    ├── base.cr            # Abstract class Tilerender::Base — defines full public API
    ├── command_line.cr    # CLI renderer implementation (buffered, requires flush)
    └── tcp.cr             # TCP server renderer (unbuffered, port from ENV or arg)
```

## Specs (`spec/`)
```
spec/
├── spec_helper.cr         # require "spec" + "../src/tilerender"
├── command_line_spec.cr   # Tests for CommandLine interface
└── tcp_spec.cr            # Tests for TCP interface (binds local port)
```

## Key boundaries
- `require "tilerender"` → loads color, base interface, version (no concrete interface)
- `require "tilerender/interfaces/command_line"` → loads CLI renderer
- `require "tilerender/interfaces/tcp"` → loads TCP server renderer
- All public methods defined in `interfaces/base.cr` as abstract; each interface implements them
