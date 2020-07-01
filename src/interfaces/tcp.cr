require "socket"

module Tilerender

	class TCP < Base
		private macro send_command_to_sockets( bytes )
			@connections.each &.write( {{ bytes }} )
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

		def initialize( port : Int32 = ENV[ "INTERFACE_PORT" ].to_i, wait_first_connection : Bool = true )
			@server = TCPServer.new port
			@connections = Array( TCPSocket ).new

			spawn handle_client client if wait_first_connection && ( client = @server.accept? )

			spawn do
				while client = @server.accept?
					spawn handle_client client.not_nil!
				end
			end
		end

		def dimensions( width : UInt16, height : UInt16 ) : Void
			bytes = Bytes.new 5
			bytes[ 0 ] = Command::UpdateDimensions.value

			{ width, height }.each_with_index{|coordinate, index|
				bytes[ index * 2 + 1 ] = ( ( coordinate >> 8 ) & 0xff ).to_u8
				bytes[ index * 2 + 2 ] = ( coordinate & 0xff ).to_u8
			}

			send_command_to_sockets bytes
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
		end

		def close_connection : Void
			@server.close
			@connections.clear
		end

		private def socket_colorize_command( command : Command, x : UInt16, y : UInt16, color : Color ) : Void
			bytes = Bytes.new 8

			bytes[ 0 ] = command.value
			bytes[ 5 ], bytes[ 6 ], bytes[ 7 ] = pick_color color
			set_coordinates bytes, x, y

			send_command_to_sockets bytes
		end

		private def handle_client( client : TCPSocket ) : Void
			@connections << client
			client.gets 1 # Waiting for transmit only, do not receive any byte: in any case disconnect the client
			client.close
			@connections.delete client
		end
	end

end
