module Tilerender

	class CommandLine < Base
		Reset = "\e[H\e[J\e[3J"
		Clear = "\e[0m"

		alias BackgroundMap = Hash( Tuple( UInt16, UInt16 ), Color )

		getter width, height

		@width : UInt16
		@height : UInt16
		@buffer : String
		@background : BackgroundMap

		def initialize
			@width = 0
			@height = 0
			@buffer = ""
			@background = BackgroundMap.new
		end

		def dimensions( @width, @height ) : Void
			@buffer = ""
			@background.clear
		end

		def reset : Void
			print Reset if @visible
			@buffer = ""
			@background.clear
		end

		def clear : Void
			@buffer = ""
			return unless @visible

			result = String.build{|string|
				previous_color : Color? = nil

				string << Clear << Reset

				@height.times{|y|
					@width.times{|x|
						if color = @background[ { x, y } ]?
							if color != previous_color
								colorize color, string
								previous_color = color
							end
						elsif previous_color
							string << Clear
							previous_color = nil
						end

						string << ' '
					}

					string << Clear if previous_color
					string << '\n'
					previous_color = nil
				}
			}

			print result
		end

		def background( x : UInt16, y : UInt16, color : Color ) : Void
			return if x >= @width || y >= @height
			@background[ { x, y } ] = color

			# This is a bug when background placed over foreground, it rewrites foreground color.
			# Ignore it. Assume that background will always be placed before any foreground entity.
			subject x, y, color if @visible
		end

		def foreground( x : UInt16, y : UInt16, color : Color ) : Void
			subject x, y, color if @visible && x < @width && y < @height
		end

		def empty( x : UInt16, y : UInt16 ) : Void
			return unless @visible
			color = @background[ { x, y } ]?
			subject x, y, color || Color::Empty
		end

		def flush : Void
			if @visible
				@buffer += String.build{ |string| line string } unless @buffer.empty?
				print @buffer
			end

			@buffer = ""
		end

		def hide : Void
			@visible = false
		end

		def show : Void
			@visible = true
		end

		private def colorize( color : Color, io : String::Builder ) : Void
			return io << Clear if color.empty?

			value = case color
				when .black? then "016"
				when .blue? then "021"
				when .cyan? then "051"
				when .gray? then "244"
				when .green? then "028"
				when .lime? then "046"
				when .magenta? then "201"
				when .maroon? then "088"
				when .navy? then "017"
				when .orange? then "208"
				when .pink? then "219"
				when .purple? then "053"
				when .red? then "196"
				when .silver? then "250"
				when .teal? then "030"
				when .white? then "255"
				when .yellow? then "226"
				else raise ArgumentError.new "Should not be here"
			end

			io << "\e[48;5;" << value << 'm'
		end

		private def subject( x : UInt16, y : UInt16, color : Color ) : Void
			@buffer += String.build{|string|
				move x, y, string
				colorize color, string
				string << ' '
				string << Clear unless color.empty?
			}
		end

		private def move( x : UInt16, y : UInt16, io : String::Builder ) : Void
			io << "\x1b[#{ y + 1 };#{ x + 1 }H"
		end

		private def line( io : String::Builder ) : Void
			move @width, @height, io
			io << '\n'
		end
	end

end
