module Tilerender
  abstract class Base
    getter visible

    @visible : Bool = true

    abstract def reset : Void
    abstract def clear : Void
    abstract def dimensions(width : UInt16, height : UInt16) : Void

    abstract def background(x : UInt16, y : UInt16, color : Color) : Void
    abstract def background(x : UInt16, y : UInt16, red : UInt8, green : UInt8, blue : UInt8) : Void

    abstract def foreground(x : UInt16, y : UInt16, color : Color) : Void
    abstract def foreground(x : UInt16, y : UInt16, red : UInt8, green : UInt8, blue : UInt8) : Void

    abstract def text(message : String) : Void

    abstract def empty(x : UInt16, y : UInt16) : Void
    abstract def flush : Void

    def hide : Void
      @visible = false
    end

    def show : Void
      @visible = true
    end
  end
end
