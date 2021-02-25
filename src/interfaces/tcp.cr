require "socket"

module Tilerender

	class TCP < Base
		private macro send_command_to_sockets( bytes )
			@connections.each{|connection|
				begin
					connection.write( {{ bytes }} )
				rescue IO::Error
					connection.close
					@connections.delete connection
				end
			}
		end

		private macro pick_color( color )
			case {{ color }}
				when .black? then { 0_u8, 0_u8, 0_u8 }
				when .blue? then { 0_u8, 0_u8, 184_u8 }
				when .cyan? then { 0_u8, 255_u8, 255_u8 }
				when .gray? then { 128_u8, 128_u8, 128_u8 }
				when .green? then { 0_u8, 192_u8, 0_u8 }
				when .lime? then { 191_u8, 255_u8, 0_u8 }
				when .magenta? then { 255_u8, 0_u8, 255_u8 }
				when .maroon? then { 128_u8, 0_u8, 0_u8 }
				when .navy? then { 0_u8, 0_u8, 128_u8 }
				when .orange? then { 255_u8, 165_u8, 0_u8 }
				when .pink? then { 255_u8, 192_u8, 203_u8 }
				when .purple? then { 128_u8, 0_u8, 128_u8 }
				when .red? then { 255_u8, 0_u8, 0_u8 }
				when .silver? then { 192_u8, 192_u8, 192_u8 }
				when .teal? then { 0_u8, 128_u8, 128_u8 }
				when .white? then { 255_u8, 255_u8, 255_u8 }
				when .yellow? then { 255_u8, 255_u8, 0_u8 }
				else raise ArgumentError.new "Should not be here"
			end
		end

		private macro set_coordinates( bytes, x, y )
			{{ bytes }}[ 1 ] = ( ( {{ x }} >> 8 ) & 0xff ).to_u8
			{{ bytes }}[ 2 ] = ( {{ x }} & 0xff ).to_u8
			{{ bytes }}[ 3 ] = ( ( {{ y }} >> 8 ) & 0xff ).to_u8
			{{ bytes }}[ 4 ] = ( {{ y }} & 0xff ).to_u8
		end

		enum Command : UInt8
			Reset
			Clear
			UpdateDimensions
			SetBackground
			SetForeground
			Empty
			Text
		end

		alias BackgroundMap = Hash( Tuple( UInt16, UInt16 ), BaseColor )

		DIMENSION_BYTES = Bytes.new 5, Command::UpdateDimensions.value
		EMPTY_BYTES = Bytes.new 5, Command::Empty.value
		COLORIZE_BYTES = Bytes.new 8

		@server : TCPServer
		@connections : Array( TCPSocket )

		@width : UInt16
		@height : UInt16

		@background : BackgroundMap

		def initialize( port : Int32 = ENV[ "INTERFACE_PORT" ].to_i, wait_first_connection : Bool = true )
			@server = TCPServer.new port
			@connections = Array( TCPSocket ).new

			@width = 0
			@height = 0

			@background = BackgroundMap.new

			if wait_first_connection && ( subject = @server.accept? )
				client = subject.not_nil!
				@connections << client
				spawn handle_client client, false
			end

			spawn do
				while subject = @server.accept?
					client = subject.not_nil!
					@connections << client
					spawn handle_client client
				end
			end
		end

		def dimensions( @width, @height ) : Void
			@background.clear

			{ @width, @height }.each_with_index{|coordinate, index|
				DIMENSION_BYTES[ index * 2 + 1 ] = ( ( coordinate >> 8 ) & 0xff ).to_u8
				DIMENSION_BYTES[ index * 2 + 2 ] = ( coordinate & 0xff ).to_u8
			}

			send_command_to_sockets DIMENSION_BYTES if @visible
		end

		def reset : Void
			@background.clear
			send_command_to_sockets Bytes.new( 1 ){ Command::Reset.value } if @visible
		end

		def clear : Void
			send_command_to_sockets Bytes.new( 1 ){ Command::Clear.value } if @visible
		end

		def background( x : UInt16, y : UInt16, color : Color ) : Void
			return if x >= @width || y >= @height
			@background[ { x, y } ] = color
			socket_colorize_command Command::SetBackground, x, y, color if @visible
		end

		def background( x : UInt16, y : UInt16, red : UInt8, green : UInt8, blue : UInt8 ) : Void
			return if x >= @width || y >= @height
			@background[ { x, y } ] = RGBColor.new red: red, green: green, blue: blue
			socket_colorize_command Command::SetBackground, x, y, red, green, blue if @visible
		end

		def foreground( x : UInt16, y : UInt16, color : Color ) : Void
			socket_colorize_command Command::SetForeground, x, y, color if @visible && x < @width && y < @height
		end

		def foreground( x : UInt16, y : UInt16, red : UInt8, green : UInt8, blue : UInt8 ) : Void
			socket_colorize_command Command::SetForeground, x, y, red, green, blue if @visible && x < @width && y < @height
		end

		def text( message : String ) : Void
			return if message.empty?
			length = message.bytesize

			raise ArgumentError.new "Message limit exceeded: #{ length } over 65535" if length > 65535

			bytes = Bytes.new length + 3
			bytes[ 0 ] = Command::Text.value
			bytes[ 1 ] = ( ( length >> 8 ) & 0xff ).to_u8
			bytes[ 2 ] = ( length & 0xff ).to_u8
			message.bytes.each_with_index{ |byte, index| bytes[ index + 3 ] = byte }

			send_command_to_sockets bytes
		end

		def empty( x : UInt16, y : UInt16 ) : Void
			return if !@visible || x >= @width || y >= @height
			set_coordinates EMPTY_BYTES, x, y
			send_command_to_sockets EMPTY_BYTES
		end

		def flush : Void
			# TODO: Make some buffer
			return unless @visible

			@background.each{|(x, y), color|
				if color.class == Tilerender::Color
					socket_colorize_command Command::SetBackground, x, y, color.as( Tilerender::Color )
				else
					socket_colorize_command Command::SetBackground, x, y, color.as( Tilerender::RGBColor ).red, color.as( Tilerender::RGBColor ).green, color.as( Tilerender::RGBColor ).blue
				end
			}
		end

		def close_connection : Void
			@server.close
			@connections.each &.close
			@connections.clear
		end

		def show
			super
			send_command_to_sockets DIMENSION_BYTES
		end

		private def socket_colorize_command( command : Command, x : UInt16, y : UInt16, color : Color ) : Void
			COLORIZE_BYTES[ 0 ] = command.value
			COLORIZE_BYTES[ 5 ], COLORIZE_BYTES[ 6 ], COLORIZE_BYTES[ 7 ] = pick_color color
			set_coordinates COLORIZE_BYTES, x, y
			send_command_to_sockets COLORIZE_BYTES
		end

		private def socket_colorize_command( command : Command, x : UInt16, y : UInt16, red : UInt8, green : UInt8, blue : UInt8 ) : Void
			COLORIZE_BYTES[ 0 ], COLORIZE_BYTES[ 5 ], COLORIZE_BYTES[ 6 ], COLORIZE_BYTES[ 7 ] = command.value, red, green, blue
			set_coordinates COLORIZE_BYTES, x, y
			send_command_to_sockets COLORIZE_BYTES
		end

		private def handle_client( client : TCPSocket, send_dimensions : Bool = true ) : Void
			client.write DIMENSION_BYTES if send_dimensions && @width > 0 && @height > 0
			client.gets 1 # Waiting for transmit only, do not receive any byte: in that case disconnect the client
		rescue IO::Error # TODO: When server closes raises this error on trying read from socket
		ensure
			client.close
			@connections.delete client
		end
	end

end
