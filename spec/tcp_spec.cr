require "./spec_helper"
require "../src/interfaces/tcp"

describe Tilerender::TCP do
  describe "#dimensions" do
    it "sends dimension command" do
      interface = Tilerender::TCP.new 9999, wait_first_connection: false
      client = TCPSocket.new "localhost", 9999
      sleep 0.001 # Async wait for connections update

      interface.dimensions 271_u16, 64028_u16

      data = Bytes.new 10
      client.read data
      client.close
      interface.close_connection

      data.should eq(Bytes[2, 1, 15, 250, 28, 0, 0, 0, 0, 0])
    end
  end

  describe "#reset" do
    it "sends reset command" do
      interface = Tilerender::TCP.new 9999, wait_first_connection: false
      client = TCPSocket.new "localhost", 9999
      sleep 0.001 # Async wait for connections update

      interface.reset

      data = Bytes.new 10, 255
      client.read data
      client.close
      interface.close_connection

      data.should eq(Bytes[0, 255, 255, 255, 255, 255, 255, 255, 255, 255])
    end
  end

  describe "#clear" do
    it "sends clear command" do
      interface = Tilerender::TCP.new 9999, wait_first_connection: false
      client = TCPSocket.new "localhost", 9999
      sleep 0.001 # Async wait for connections update

      interface.clear

      data = Bytes.new 10, 255
      client.read data
      client.close
      interface.close_connection

      data.should eq(Bytes[1, 255, 255, 255, 255, 255, 255, 255, 255, 255])
    end
  end

  describe "#background" do
    context "with Color" do
      it "sends background command" do
        interface = Tilerender::TCP.new(9999, wait_first_connection: false).tap &.dimensions(32176_u16, 260_u16)
        client = TCPSocket.new "localhost", 9999
        sleep 0.001 # Async wait for connections update

        client.read Bytes.new(5)

        interface.background 32175, 259, :red

        data = Bytes.new 10, 12
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[3, 125, 175, 1, 3, 255, 0, 0, 12, 12])
      end
    end

    context "with RGBColor" do
      it "sends background command" do
        interface = Tilerender::TCP.new(9999, wait_first_connection: false).tap &.dimensions(32176_u16, 260_u16)
        client = TCPSocket.new "localhost", 9999
        sleep 0.001 # Async wait for connections update

        client.read Bytes.new(5)

        interface.background 32175, 259, 12, 23, 34

        data = Bytes.new 10, 15
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[3, 125, 175, 1, 3, 12, 23, 34, 15, 15])
      end
    end
  end

  describe "#foreground" do
    context "with Color" do
      it "sends foreground command" do
        interface = Tilerender::TCP.new(9999, wait_first_connection: false).tap &.dimensions(260_u16, 32176_u16)
        client = TCPSocket.new "localhost", 9999
        sleep 0.001 # Async wait for connections update

        client.read Bytes.new(5)

        interface.foreground 259, 32175, :silver

        data = Bytes.new 10, 255
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[4, 1, 3, 125, 175, 192, 192, 192, 255, 255])
      end
    end

    context "with RGBColor" do
      it "sends foreground command" do
        interface = Tilerender::TCP.new(9999, wait_first_connection: false).tap &.dimensions(260_u16, 32176_u16)
        client = TCPSocket.new "localhost", 9999
        sleep 0.001 # Async wait for connections update

        client.read Bytes.new(5)

        interface.foreground 259, 32175, 25, 53, 77

        data = Bytes.new 10, 254
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[4, 1, 3, 125, 175, 25, 53, 77, 254, 254])
      end
    end
  end

  describe "#text" do
    it "sends short message" do
      interface = Tilerender::TCP.new(9999, wait_first_connection: false).tap &.dimensions(1753_u16, 12705_u16)
      client = TCPSocket.new "localhost", 9999
      sleep 0.001 # Async wait for connections update

      client.read Bytes.new(5)

      interface.text "abc"

      data = Bytes.new 7, 250
      client.read data
      client.close
      interface.close_connection

      data.should eq(Bytes[6, 0, 3, 97, 98, 99, 250])
    end

    it "sends long message" do
      interface = Tilerender::TCP.new(9999, wait_first_connection: false).tap &.dimensions(1753_u16, 12705_u16)
      client = TCPSocket.new "localhost", 9999
      sleep 0.001 # Async wait for connections update

      client.read Bytes.new(5)

      interface.text "a" * 65535

      data = Bytes.new 65539, 177
      result = Bytes.new 65539, 97
      result[0] = 6
      result[1] = 255
      result[2] = 255
      result[-1] = 177

      client.read data
      client.close
      interface.close_connection

      data.should eq(result)
    end

    it "raises error" do
      interface = Tilerender::TCP.new(9999, wait_first_connection: false).tap &.dimensions(1753_u16, 12705_u16)
      client = TCPSocket.new "localhost", 9999
      sleep 0.001 # Async wait for connections update

      client.read Bytes.new(5)

      text = "a" * 65536
      expect_raises(ArgumentError, "Message limit exceeded: 65536 over 65535") { interface.text text }

      client.close
      interface.close_connection
    end
  end

  describe "#toggle_lines" do
    it "sends toggle lines command" do
      interface = Tilerender::TCP.new 9999, wait_first_connection: false
      client = TCPSocket.new "localhost", 9999
      sleep 0.001 # Async wait for connections update

      interface.toggle_lines

      data = Bytes.new 10, 255
      client.read data
      client.close
      interface.close_connection

      data.should eq(Bytes[7, 0, 255, 255, 255, 255, 255, 255, 255, 255])
    end
  end

  describe "#empty" do
    it "sends empty command" do
      interface = Tilerender::TCP.new(9999, wait_first_connection: false).tap &.dimensions(1753_u16, 12705_u16)
      client = TCPSocket.new "localhost", 9999
      sleep 0.001 # Async wait for connections update

      client.read Bytes.new(5)

      interface.empty 1752, 12704

      data = Bytes.new 10, 128
      client.read data
      client.close
      interface.close_connection

      data.should eq(Bytes[5, 6, 216, 49, 160, 128, 128, 128, 128, 128])
    end
  end

  describe "with commands chain" do
    context "with Color" do
      it "sends stream commands" do
        interface = Tilerender::TCP.new 9999, wait_first_connection: false
        client = TCPSocket.new "localhost", 9999
        sleep 0.001 # Async wait for connections update

        interface.dimensions 32030_u16, 350_u16
        interface.reset
        interface.background 15, 24, :gray
        interface.foreground 29, 278, :magenta

        data = Bytes.new 25, 8
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[2, 125, 30, 1, 94, 0, 3, 0, 15, 0, 24, 128, 128, 128, 4, 0, 29, 1, 22, 255, 0, 255, 8, 8, 8])
      end
    end

    context "with RGBColor" do
      it "sends stream commands" do
        interface = Tilerender::TCP.new 9999, wait_first_connection: false
        client = TCPSocket.new "localhost", 9999
        sleep 0.001 # Async wait for connections update

        interface.dimensions 30_u16, 350_u16
        interface.reset
        interface.background 15, 24, 11, 22, 33
        interface.foreground 29, 278, 27, 89, 93

        data = Bytes.new 25, 4
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[2, 0, 30, 1, 94, 0, 3, 0, 15, 0, 24, 11, 22, 33, 4, 0, 29, 1, 22, 27, 89, 93, 4, 4, 4])
      end
    end
  end

  describe "#hide" do
    context "with Color" do
      it "disables output" do
        interface = Tilerender::TCP.new 9999, wait_first_connection: false
        client = TCPSocket.new "localhost", 9999
        sleep 0.001 # Async wait for connections update

        interface.hide

        interface.dimensions 11_u16, 16_u16
        interface.reset
        interface.background 4, 15, :navy
        interface.foreground 29, 278, :maroon
        interface.flush

        interface.show

        data = Bytes.new 8, 15
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[2, 0, 11, 0, 16, 15, 15, 15])
      end
    end

    context "with RGBColor" do
      it "disables output" do
        interface = Tilerender::TCP.new 9999, wait_first_connection: false
        client = TCPSocket.new "localhost", 9999
        client.read_timeout = 0.1
        sleep 0.001 # Async wait for connections update

        interface.hide

        interface.dimensions 11_u16, 1_u16
        interface.reset
        interface.background 4, 15, 12, 23, 34
        interface.foreground 29, 278, 35, 24, 11
        interface.flush

        interface.show

        data = Bytes.new 8, 15
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[2, 0, 11, 0, 1, 15, 15, 15])
      end
    end
  end

  describe "#show" do
    context "with Color" do
      it "enables output" do
        interface = Tilerender::TCP.new 9999, wait_first_connection: false
        client = TCPSocket.new "localhost", 9999
        sleep 0.001 # Async wait for connections update

        interface.hide
        interface.dimensions 1_u16, 25_u16
        interface.show
        interface.background 0, 0, :orange

        data = Bytes.new 15, 71
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[2, 0, 1, 0, 25, 3, 0, 0, 0, 0, 255, 165, 0, 71, 71])
      end
    end

    context "with RGBColor" do
      it "enables output" do
        interface = Tilerender::TCP.new 9999, wait_first_connection: false
        client = TCPSocket.new "localhost", 9999
        sleep 0.001 # Async wait for connections update

        interface.hide
        interface.dimensions 1_u16, 25_u16
        interface.show
        interface.background 0, 0, 43, 32, 21

        data = Bytes.new 15, 11
        client.read data
        client.close
        interface.close_connection

        data.should eq(Bytes[2, 0, 1, 0, 25, 3, 0, 0, 0, 0, 43, 32, 21, 11, 11])
      end
    end
  end
end
