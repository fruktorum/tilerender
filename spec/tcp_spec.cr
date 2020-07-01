require "./spec_helper"
require "../src/interfaces/tcp"

describe Tilerender::TCP do
	describe "#dimensions" do
		it "sends dimension command" do
			interface = Tilerender::TCP.new wait_first_connection: false
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			interface.dimensions 271_u16, 64028_u16

			data = Bytes.new 10
			client.read data
			client.close
			interface.close_connection

			data.should eq( Bytes[ 2, 1, 15, 250, 28, 0, 0, 0, 0, 0 ] )
		end
	end

	describe "#reset" do
		it "sends reset command" do
			interface = Tilerender::TCP.new wait_first_connection: false
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			interface.reset

			data = Bytes.new 10, 255
			client.read data
			client.close
			interface.close_connection

			data.should eq( Bytes[ 0, 255, 255, 255, 255, 255, 255, 255, 255, 255 ] )
		end
	end

	describe "#clear" do
		it "sends clear command" do
			interface = Tilerender::TCP.new wait_first_connection: false
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			interface.clear

			data = Bytes.new 10, 255
			client.read data
			client.close
			interface.close_connection

			data.should eq( Bytes[ 1, 255, 255, 255, 255, 255, 255, 255, 255, 255 ] )
		end
	end

	describe "#background" do
		it "sends background command" do
			interface = Tilerender::TCP.new wait_first_connection: false
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			interface.background 32175_u16, 259_u16, :red

			data = Bytes.new 10, 12
			client.read data
			client.close
			interface.close_connection

			data.should eq( Bytes[ 3, 125, 175, 1, 3, 255, 0, 0, 12, 12 ] )
		end
	end

	describe "#foreground" do
		it "sends foreground command" do
			interface = Tilerender::TCP.new wait_first_connection: false
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			interface.foreground 259_u16, 32175_u16, :silver

			data = Bytes.new 10, 255
			client.read data
			client.close
			interface.close_connection

			data.should eq( Bytes[ 4, 1, 3, 125, 175, 192, 192, 192, 255, 255 ] )
		end
	end

	describe "#empty" do
		it "sends empty command" do
			interface = Tilerender::TCP.new wait_first_connection: false
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			interface.empty 1752_u16, 12704_u16

			data = Bytes.new 10, 128
			client.read data
			client.close
			interface.close_connection

			data.should eq( Bytes[ 5, 6, 216, 49, 160, 128, 128, 128, 128, 128 ] )
		end
	end

	describe "with commands chain" do
		it "sends stream commands" do
			interface = Tilerender::TCP.new wait_first_connection: false
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			interface.dimensions 23_u16, 350_u16
			interface.reset
			interface.background 15_u16, 24_u16, :gray
			interface.foreground 29_u16, 278_u16, :magenta

			data = Bytes.new 25, 8
			client.read data
			client.close
			interface.close_connection

			data.should eq( Bytes[ 2, 0, 23, 1, 94, 0, 3, 0, 15, 0, 24, 128, 128, 128, 4, 0, 29, 1, 22, 255, 0, 255, 8, 8, 8 ] )
		end
	end

	describe "#hide" do
		it "disables output" do
			interface = Tilerender::TCP.new wait_first_connection: false
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			client.read_timeout = 1
			sleep 0.001 # Async wait for connections update

			interface.hide

			interface.dimensions 11_u16, 0_u16
			interface.reset
			interface.background 4_u16, 15_u16, :navy
			interface.foreground 29_u16, 278_u16, :maroon
			interface.flush

			interface.show

			begin
				byte = client.read_byte
			rescue IO::TimeoutError
				byte = nil
			end

			client.close
			interface.close_connection

			byte.should be_nil
		end
	end

	describe "#show" do
		it "enables output" do
			interface = Tilerender::TCP.new wait_first_connection: false
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			interface.hide
			interface.dimensions 1_u16, 25_u16
			interface.show
			interface.background 0_u16, 0_u16, :orange

			data = Bytes.new 10, 71
			client.read data
			client.close
			interface.close_connection

			data.should eq( Bytes[ 3, 0, 0, 0, 0, 255, 165, 0, 71, 71 ] )
		end
	end
end
