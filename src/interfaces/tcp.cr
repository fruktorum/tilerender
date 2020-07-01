require "socket"

module Tilerender

	class TCP < Base
		private macro send_command_to_sockets( bytes )
			return unless @visible

			@connections.each{|connection|
				begin
					connection.write( {{ bytes }} )
				rescue IO::Error
					connection.close
					@connections.delete connection
				end
			}
		end

		private macro socket_byte_command( command )
			send_command_to_sockets Bytes.new( 1 ){ {{ command }}.value }
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

		private macro dimension_bytes
			bytes = Bytes.new 5
			bytes[ 0 ] = Command::UpdateDimensions.value

			{ @width, @height }.each_with_index{|coordinate, index|
				bytes[ index * 2 + 1 ] = ( ( coordinate >> 8 ) & 0xff ).to_u8
				bytes[ index * 2 + 2 ] = ( coordinate & 0xff ).to_u8
			}

			bytes
		end

		enum Command : UInt8
			Reset
			Clear
			UpdateDimensions
			SetBackground
			SetForeground
			Empty
		end

		@server : TCPServer
		@connections : Array( TCPSocket )

		@width : UInt16
		@height : UInt16

		def initialize( port : Int32 = ENV[ "INTERFACE_PORT" ].to_i, wait_first_connection : Bool = true )
			@server = TCPServer.new port
			@connections = Array( TCPSocket ).new

			@width = 0
			@height = 0

			if wait_first_connection && ( subject = @server.accept? )
				client = subject.not_nil!
				@connections << client.not_nil!
				spawn handle_client client
			end

			spawn do
				while subject = @server.accept?
					client = subject.not_nil!
					@connections << client.not_nil!
					spawn handle_client client
				end
			end
		end

		def dimensions( @width, @height ) : Void
			return unless @visible
			send_command_to_sockets dimension_bytes
		end

		def reset : Void
			socket_byte_command Command::Reset
		end

		def clear : Void
			socket_byte_command Command::Clear
		end

		def background( x : UInt16, y : UInt16, color : Color ) : Void
			socket_colorize_command Command::SetBackground, x, y, color
		end

		def foreground( x : UInt16, y : UInt16, color : Color ) : Void
			socket_colorize_command Command::SetForeground, x, y, color
		end

		def empty( x : UInt16, y : UInt16 ) : Void
			bytes = Bytes.new 5

			bytes[ 0 ] = Command::Empty.value
			set_coordinates bytes, x, y

			send_command_to_sockets bytes
		end

		def flush : Void
			# TODO: Make some buffer before
		end

		def close_connection : Void
			@server.close
			@connections.each &.close
			@connections.clear
		end

		private def socket_colorize_command( command : Command, x : UInt16, y : UInt16, color : Color ) : Void
			return unless @visible

			bytes = Bytes.new 8

			bytes[ 0 ] = command.value
			bytes[ 5 ], bytes[ 6 ], bytes[ 7 ] = pick_color color
			set_coordinates bytes, x, y

			send_command_to_sockets bytes
		end

		private def handle_client( client : TCPSocket ) : Void
			client.write dimension_bytes if @width > 0 && @height > 0
			client.gets 1 # Waiting for transmit only, do not receive any byte: in any case disconnect the client
		rescue IO::Error # TODO: When server closes raises this error on trying read from socket
		ensure
			client.close
			@connections.delete client
		end
	end

end
