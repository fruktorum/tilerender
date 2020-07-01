require "./spec_helper"
require "../src/interfaces/tcp"

module Tilerender
	TestInterface = Tilerender::TCP.new wait_first_connection: false
end

describe Tilerender::TCP do
	after_all{ Tilerender::TestInterface.close_connection }

	describe "#dimensions" do
		it "sends dimension command" do
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			Tilerender::TestInterface.dimensions 271_u16, 64028_u16

			data = Bytes.new 10
			client.read data
			client.close

			data.should eq( Bytes[ 2, 1, 15, 250, 28, 0, 0, 0, 0, 0 ] )
		end
	end

	describe "#reset" do
		it "sends reset command" do
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			Tilerender::TestInterface.reset

			data = Bytes.new 10, 255
			client.read data
			client.close
			data.should eq( Bytes[ 0, 255, 255, 255, 255, 255, 255, 255, 255, 255 ] )
		end
	end

	describe "#clear" do
		it "sends clear command" do
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			Tilerender::TestInterface.clear

			data = Bytes.new 10, 255
			client.read data
			client.close
			data.should eq( Bytes[ 1, 255, 255, 255, 255, 255, 255, 255, 255, 255 ] )
		end
	end

	describe "#background" do
		it "sends background command" do
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			Tilerender::TestInterface.background 32175_u16, 259_u16, Tilerender::Color::Red

			data = Bytes.new 10, 12
			client.read data
			client.close
			data.should eq( Bytes[ 3, 125, 175, 1, 3, 255, 0, 0, 12, 12 ] )
		end
	end

	describe "#foreground" do
		it "sends foreground command" do
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			Tilerender::TestInterface.foreground 259_u16, 32175_u16, Tilerender::Color::Silver

			data = Bytes.new 10, 255
			client.read data
			client.close
			data.should eq( Bytes[ 4, 1, 3, 125, 175, 192, 192, 192, 255, 255 ] )
		end
	end

	describe "#empty" do
		it "sends empty command" do
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			Tilerender::TestInterface.empty 1752_u16, 12704_u16

			data = Bytes.new 10, 128
			client.read data
			client.close
			data.should eq( Bytes[ 5, 6, 216, 49, 160, 128, 128, 128, 128, 128 ] )
		end
	end

	describe "with commands chain" do
		it "sends stream commands" do
			client = TCPSocket.new "localhost", ENV[ "INTERFACE_PORT" ]
			sleep 0.001 # Async wait for connections update

			Tilerender::TestInterface.dimensions 23_u16, 350_u16
			Tilerender::TestInterface.reset
			Tilerender::TestInterface.background 15_u16, 24_u16, Tilerender::Color::Gray
			Tilerender::TestInterface.foreground 29_u16, 278_u16, Tilerender::Color::Magenta

			data = Bytes.new 25, 8
			client.read data
			client.close
			data.should eq( Bytes[ 2, 0, 23, 1, 94, 0, 3, 0, 15, 0, 24, 128, 128, 128, 4, 0, 29, 1, 22, 255, 0, 255, 8, 8, 8 ] )
		end
	end
end
