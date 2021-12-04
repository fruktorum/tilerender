require "./spec_helper"
require "../src/interfaces/command_line"

class Tilerender::CommandLine
  getter buffer, stdout_buffer, background

  @stdout_buffer : String = ""

  def print(payload)
    @stdout_buffer += "#{payload}"
  end

  def puts(payload)
    raise Exception.new "Should not be called, use `print` instead"
  end

  def clear_stdout_buffer : Void
    @stdout_buffer = ""
  end

  # Private method aliases to be able for testing it
  def _colorize(string : String::Builder, color : Tilerender::Color)
    colorize string, color
  end

  # Private method aliases to be able for testing it
  def _colorize(string : String::Builder, red : UInt8, green : UInt8, blue : UInt8)
    colorize string, Tilerender::RGBColor.new(red: red, green: green, blue: blue)
  end
end

def create_interface : Tilerender::CommandLine
  Tilerender::CommandLine.new.tap &.dimensions(3_u16, 2_u16)
end

describe Tilerender::CommandLine do
  describe "#colorize" do
    context "with Color" do
      it "has reset code" do
        interface = create_interface
        result = String.build { |string| interface._colorize string, Tilerender::Color::Empty }
        result.should eq("\e[0m")
      end

      it "has black color code" do
        interface = create_interface
        result = String.build { |string| interface._colorize string, Tilerender::Color::Black }
        result.should eq("\e[48;5;016m")
      end

      it "has red color code" do
        interface = create_interface
        result = String.build { |string| interface._colorize string, Tilerender::Color::Red }
        result.should eq("\e[48;5;196m")
      end
    end

    context "with RGBColor" do
      it "has RGB code" do
        interface = create_interface
        result = String.build { |string| interface._colorize string, 12, 23, 34 }
        result.should eq("\e[48;2;12;23;34m")
      end
    end
  end

  describe "#dimensions" do
    it "has dimensions" do
      interface = create_interface
      interface.width.should eq(3)
      interface.height.should eq(2)
    end

    it "sets new dimensions" do
      interface = create_interface
      interface.dimensions 4_u16, 7_u16
      interface.width.should eq(4)
      interface.height.should eq(7)
    end

    it "does not print anything" do
      interface = create_interface
      interface.dimensions 4_u16, 7_u16
      interface.stdout_buffer.should be_empty
    end

    context "with Color" do
      it "resets buffer" do
        interface = create_interface
        interface.background 1, 1, :red
        interface.buffer.should_not be_empty

        interface.dimensions 3_u16, 2_u16
        interface.buffer.should be_empty
      end

      it "resets background" do
        interface = create_interface
        interface.background 1, 1, :red
        interface.background.should_not be_empty

        interface.dimensions 3_u16, 2_u16
        interface.background.should be_empty
      end
    end

    context "with RGBColor" do
      it "resets buffer" do
        interface = create_interface
        interface.background 1, 1, 12, 23, 34
        interface.buffer.should_not be_empty

        interface.dimensions 3_u16, 2_u16
        interface.buffer.should be_empty
      end

      it "resets background" do
        interface = create_interface
        interface.background 1, 1, 12, 23, 34
        interface.background.should_not be_empty

        interface.dimensions 3_u16, 2_u16
        interface.background.should be_empty
      end
    end
  end

  describe "#reset" do
    context "with Color" do
      it "resets background" do
        interface = create_interface
        interface.background 1, 0, :red
        interface.reset
        interface.background.size.should eq(0)
      end

      it "resets buffer" do
        interface = create_interface
        interface.background 0, 0, :red
        interface.foreground 1, 0, :red
        interface.reset
        interface.buffer.should be_empty
      end

      it "prints reset sequence only" do
        interface = create_interface
        interface.foreground 1, 0, :red
        interface.background 1, 0, :red
        interface.reset
        interface.stdout_buffer.should eq("\e[H\e[J\e[3J")
      end
    end

    context "with RGBColor" do
      it "resets background" do
        interface = create_interface
        interface.background 1, 0, 12, 23, 34
        interface.reset
        interface.background.size.should eq(0)
      end

      it "resets buffer" do
        interface = create_interface
        interface.background 0, 0, 12, 23, 34
        interface.foreground 1, 0, 12, 23, 34
        interface.reset
        interface.buffer.should be_empty
      end

      it "prints reset sequence only" do
        interface = create_interface
        interface.foreground 1, 0, 12, 23, 34
        interface.background 1, 0, 12, 23, 34
        interface.reset
        interface.stdout_buffer.should eq("\e[H\e[J\e[3J")
      end
    end
  end

  describe "#clear" do
    context "with empty background" do
      it "fills empty" do
        interface = create_interface
        interface.clear
        interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n   \n")
      end

      context "with Color" do
        it "fills empty if background out of range" do
          interface = create_interface
          interface.background 3, 1, :red
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n   \n")
        end

        it "with foreground" do
          interface = create_interface
          interface.foreground 1, 1, :red
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n   \n")
        end
      end

      context "with RGBColor" do
        it "fills empty if background out of range" do
          interface = create_interface
          interface.background 3, 1, 12, 23, 34
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n   \n")
        end

        it "with foreground" do
          interface = create_interface
          interface.foreground 1, 1, 12, 23, 34
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n   \n")
        end
      end
    end

    context "with single background sector" do
      context "with Color" do
        it "fills with background in the first sector" do
          interface = create_interface
          interface.background 0, 0, :red
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J\e[48;5;196m \e[0m  \n   \n")
        end

        it "fills with background in the top middle sector" do
          interface = create_interface
          interface.background 1, 0, :red
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J \e[48;5;196m \e[0m \n   \n")
        end

        it "fills with background in the bottom middle sector" do
          interface = create_interface
          interface.background 1, 1, :red
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n \e[48;5;196m \e[0m \n")
        end

        it "fills with background in the last sector" do
          interface = create_interface
          interface.background 2, 1, :red
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n  \e[48;5;196m \e[0m\n")
        end

        context "with foreground" do
          it "with different places" do
            interface = create_interface
            interface.background 2, 1, :red
            interface.foreground 1, 1, :red
            interface.clear
            interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n  \e[48;5;196m \e[0m\n")
          end

          it "with the same place" do
            interface = create_interface
            interface.background 2, 1, :red
            interface.foreground 2, 1, :red
            interface.clear
            interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n  \e[48;5;196m \e[0m\n")
          end
        end
      end

      context "with RGBColor" do
        it "fills with background in the first sector" do
          interface = create_interface
          interface.background 0, 0, 12, 23, 34
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J\e[48;2;12;23;34m \e[0m  \n   \n")
        end

        it "fills with background in the top middle sector" do
          interface = create_interface
          interface.background 1, 0, 12, 23, 34
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J \e[48;2;12;23;34m \e[0m \n   \n")
        end

        it "fills with background in the bottom middle sector" do
          interface = create_interface
          interface.background 1, 1, 12, 23, 34
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n \e[48;2;12;23;34m \e[0m \n")
        end

        it "fills with background in the last sector" do
          interface = create_interface
          interface.background 2, 1, 12, 23, 34
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n  \e[48;2;12;23;34m \e[0m\n")
        end

        context "with foreground" do
          it "with different places" do
            interface = create_interface
            interface.background 2, 1, 12, 23, 34
            interface.foreground 1, 1, 12, 23, 34
            interface.clear
            interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n  \e[48;2;12;23;34m \e[0m\n")
          end

          it "with the same place" do
            interface = create_interface
            interface.background 2, 1, 12, 23, 34
            interface.foreground 2, 1, 12, 23, 34
            interface.clear
            interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n  \e[48;2;12;23;34m \e[0m\n")
          end
        end
      end
    end

    context "with background sectors sequence" do
      context "with Color" do
        it "fills with background in the first line" do
          interface = create_interface
          interface.background 0, 0, :red
          interface.background 1, 0, :red
          interface.background 2, 0, :red
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J\e[48;5;196m   \e[0m\n   \n")
        end

        it "fills with background in the first 2 sectors" do
          interface = create_interface
          interface.background 0, 0, :red
          interface.background 1, 0, :red
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J\e[48;5;196m  \e[0m \n   \n")
        end

        it "fills with background in the last line" do
          interface = create_interface
          interface.background 0, 1, :red
          interface.background 1, 1, :red
          interface.background 2, 1, :red
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n\e[48;5;196m   \e[0m\n")
        end

        it "does not clear background array" do
          interface = create_interface
          interface.background 3, 1, :red
          interface.background 2, 1, :red
          interface.background 0, 0, :blue
          interface.clear
          interface.background.size.should eq(2)
        end
      end

      context "with RGBColor" do
        it "fills with background in the first line" do
          interface = create_interface
          interface.background 0, 0, 12, 23, 34
          interface.background 1, 0, 12, 23, 34
          interface.background 2, 0, 12, 23, 34
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J\e[48;2;12;23;34m   \e[0m\n   \n")
        end

        it "fills with background in the first 2 sectors" do
          interface = create_interface
          interface.background 0, 0, 12, 23, 34
          interface.background 1, 0, 12, 23, 34
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J\e[48;2;12;23;34m  \e[0m \n   \n")
        end

        it "fills with background in the last line" do
          interface = create_interface
          interface.background 0, 1, 12, 23, 34
          interface.background 1, 1, 12, 23, 34
          interface.background 2, 1, 12, 23, 34
          interface.clear
          interface.stdout_buffer.should eq("\e[0m\e[H\e[J\e[3J   \n\e[48;2;12;23;34m   \e[0m\n")
        end

        it "does not clear background array" do
          interface = create_interface
          interface.background 3, 1, 12, 23, 34
          interface.background 2, 1, 12, 23, 34
          interface.background 0, 0, 56, 78, 99
          interface.clear
          interface.background.size.should eq(2)
        end
      end
    end
  end

  describe "#background" do
    context "with Color" do
      it "paints background to the sector" do
        interface = create_interface
        interface.background 1, 0, :purple
        interface.buffer.should eq("\x1b[1;2H\e[48;5;053m \e[0m")
      end

      it "does not print anything" do
        interface = create_interface
        interface.background 1, 0, :red
        interface.stdout_buffer.should eq("")
      end

      it "paints several sectors" do
        interface = create_interface
        interface.background 0, 1, :red
        interface.background 2, 0, :blue
        interface.background 1, 1, :green
        interface.buffer.should eq("\x1b[2;1H\e[48;5;196m \e[0m\x1b[1;3H\e[48;5;021m \e[0m\x1b[2;2H\e[48;5;028m \e[0m")
      end

      it "saves background" do
        interface = create_interface
        interface.background 0, 1, :red
        interface.background.size.should eq(1)
        interface.background[{0, 1}].should eq(Tilerender::Color::Red)
      end

      it "does not save when out of range" do
        interface = create_interface
        interface.background 3, 0, :red
        interface.background.size.should eq(0)
      end
    end

    context "with RGBColor" do
      it "paints background to the sector" do
        interface = create_interface
        interface.background 1, 0, 28, 32, 43
        interface.buffer.should eq("\x1b[1;2H\e[48;2;28;32;43m \e[0m")
      end

      it "does not print anything" do
        interface = create_interface
        interface.background 1, 0, 12, 23, 34
        interface.stdout_buffer.should eq("")
      end

      it "paints several sectors" do
        interface = create_interface
        interface.background 0, 1, 12, 23, 34
        interface.background 2, 0, 44, 55, 77
        interface.background 1, 1, 52, 17, 89
        interface.buffer.should eq("\x1b[2;1H\e[48;2;12;23;34m \e[0m\x1b[1;3H\e[48;2;44;55;77m \e[0m\x1b[2;2H\e[48;2;52;17;89m \e[0m")
      end

      it "saves background" do
        interface = create_interface
        interface.background 0, 1, 12, 23, 34
        interface.background.size.should eq(1)
        interface.background[{0, 1}].should eq(Tilerender::RGBColor.new red: 12, green: 23, blue: 34)
      end

      it "does not save when out of range" do
        interface = create_interface
        interface.background 3, 0, 12, 23, 34
        interface.background.size.should eq(0)
      end
    end
  end

  describe "#foreground" do
    context "with Color" do
      it "paints the first sector" do
        interface = create_interface
        interface.foreground 0, 0, :red
        interface.buffer.should eq("\x1b[1;1H\e[48;5;196m \e[0m")
      end

      it "paints the first and the last sectors" do
        interface = create_interface
        interface.foreground 0, 0, :red
        interface.foreground 2, 1, :blue
        interface.buffer.should eq("\x1b[1;1H\e[48;5;196m \e[0m\x1b[2;3H\e[48;5;021m \e[0m")
      end

      it "does not paint the sector" do
        interface = create_interface
        interface.foreground 3, 0, :red
        interface.buffer.should eq("")
      end

      context "with background" do
        it "paints near the background" do
          interface = create_interface
          interface.background 0, 0, :red
          interface.foreground 1, 0, :blue
          interface.buffer.should eq("\x1b[1;1H\e[48;5;196m \e[0m\x1b[1;2H\e[48;5;021m \e[0m")
        end

        it "paints over the background" do
          interface = create_interface
          interface.background 1, 0, :red
          interface.foreground 1, 0, :blue
          interface.buffer.should eq("\x1b[1;2H\e[48;5;196m \e[0m\x1b[1;2H\e[48;5;021m \e[0m")
        end
      end
    end

    context "with RGBColor" do
      it "paints the first sector" do
        interface = create_interface
        interface.foreground 0, 0, 12, 23, 34
        interface.buffer.should eq("\x1b[1;1H\e[48;2;12;23;34m \e[0m")
      end

      it "paints the first and the last sectors" do
        interface = create_interface
        interface.foreground 0, 0, 12, 23, 34
        interface.foreground 2, 1, 44, 22, 33
        interface.buffer.should eq("\x1b[1;1H\e[48;2;12;23;34m \e[0m\x1b[2;3H\e[48;2;44;22;33m \e[0m")
      end

      it "does not paint the sector" do
        interface = create_interface
        interface.foreground 3, 0, 12, 23, 34
        interface.buffer.should eq("")
      end

      context "with background" do
        it "paints near the background" do
          interface = create_interface
          interface.background 0, 0, 12, 23, 34
          interface.foreground 1, 0, 44, 22, 33
          interface.buffer.should eq("\x1b[1;1H\e[48;2;12;23;34m \e[0m\x1b[1;2H\e[48;2;44;22;33m \e[0m")
        end

        it "paints over the background" do
          interface = create_interface
          interface.background 1, 0, 12, 23, 34
          interface.foreground 1, 0, 44, 22, 33
          interface.buffer.should eq("\x1b[1;2H\e[48;2;12;23;34m \e[0m\x1b[1;2H\e[48;2;44;22;33m \e[0m")
        end
      end
    end
  end

  describe "#text" do
    it "does not send enything" do
      interface = create_interface
      interface.text ""
      interface.stdout_buffer.should eq("")
    end

    it "sends short message" do
      interface = create_interface
      interface.text "abc"
      interface.stdout_buffer.should eq("abc\n")
    end

    it "sends long message" do
      interface = create_interface
      text = "a" * 65535

      interface.text text
      interface.stdout_buffer.should eq(text + "\n")
    end

    it "raises error" do
      interface = create_interface
      text = "a" * 65536
      expect_raises(ArgumentError, "Message limit exceeded: 65536 over 65535") { interface.text text }
    end
  end

  describe "#empty" do
    context "without entity" do
      it "clears cell" do
        interface = create_interface
        interface.empty 2, 0
        interface.buffer.should eq("\x1b[1;3H\e[0m ")
      end
    end

    context "with Color" do
      context "with background" do
        context "without entity" do
          it "fills cell by background color" do
            interface = create_interface
            interface.background 1, 0, :red

            interface.flush

            interface.empty 1, 0
            interface.buffer.should eq("\x1b[1;2H\e[48;5;196m \e[0m")
          end
        end

        context "with entity" do
          it "clears cell" do
            interface = create_interface
            interface.background 1, 0, :red
            interface.foreground 2, 0, :red

            interface.flush

            interface.empty 2, 0
            interface.buffer.should eq("\x1b[1;3H\e[0m ")
          end

          it "fills cell by background color" do
            interface = create_interface
            interface.background 1, 0, :red
            interface.foreground 1, 0, :blue

            interface.flush

            interface.empty 1, 0
            interface.buffer.should eq("\x1b[1;2H\e[48;5;196m \e[0m")
          end
        end
      end

      context "without background" do
        it "clears cell" do
          interface = create_interface
          interface.foreground 1, 0, :red

          interface.flush

          interface.empty 1, 0
          interface.buffer.should eq("\x1b[1;2H\e[0m ")
        end
      end
    end

    context "with RGBColor" do
      context "with background" do
        context "without entity" do
          it "fills cell by background color" do
            interface = create_interface
            interface.background 1, 0, 12, 23, 34

            interface.flush

            interface.empty 1, 0
            interface.buffer.should eq("\x1b[1;2H\e[48;2;12;23;34m \e[0m")
          end
        end

        context "with entity" do
          it "clears cell" do
            interface = create_interface
            interface.background 1, 0, 12, 23, 34
            interface.foreground 2, 0, 12, 23, 34

            interface.flush

            interface.empty 2, 0
            interface.buffer.should eq("\x1b[1;3H\e[0m ")
          end

          it "fills cell by background color" do
            interface = create_interface
            interface.background 1, 0, 12, 23, 34
            interface.foreground 1, 0, 25, 18, 79

            interface.flush

            interface.empty 1, 0
            interface.buffer.should eq("\x1b[1;2H\e[48;2;12;23;34m \e[0m")
          end
        end
      end

      context "without background" do
        it "clears cell" do
          interface = create_interface
          interface.foreground 1, 0, 12, 23, 34

          interface.flush

          interface.empty 1, 0
          interface.buffer.should eq("\x1b[1;2H\e[0m ")
        end
      end
    end
  end

  describe "#flush" do
    context "with Color" do
      it "clears buffer" do
        interface = create_interface
        interface.background 0, 0, :red
        interface.foreground 0, 1, :blue
        interface.flush
        interface.buffer.should be_empty
      end

      it "does not clear background" do
        interface = create_interface
        interface.background 0, 0, :red
        interface.foreground 0, 1, :blue
        interface.flush
        interface.background.should_not be_empty
      end

      it "does not print anything twice" do
        interface = create_interface
        interface.background 0, 0, :red
        interface.foreground 0, 1, :blue
        interface.flush
        interface.clear_stdout_buffer
        interface.flush
        interface.stdout_buffer.should be_empty
      end

      it "prints last sequence" do
        interface = create_interface
        interface.background 0, 0, :yellow
        interface.foreground 0, 1, :blue
        interface.flush
        interface.clear_stdout_buffer

        interface.background 2, 1, :red
        interface.flush
        interface.stdout_buffer.should eq("\x1b[2;3H\e[48;5;196m \e[0m\e[3;4H\n")
      end
    end

    context "with RGBColor" do
      it "clears buffer" do
        interface = create_interface
        interface.background 0, 0, 12, 23, 34
        interface.foreground 0, 1, 25, 57, 11
        interface.flush
        interface.buffer.should be_empty
      end

      it "does not clear background" do
        interface = create_interface
        interface.background 0, 0, 12, 23, 34
        interface.foreground 0, 1, 25, 57, 11
        interface.flush
        interface.background.should_not be_empty
      end

      it "does not print anything twice" do
        interface = create_interface
        interface.background 0, 0, 12, 23, 34
        interface.foreground 0, 1, 25, 57, 11
        interface.flush
        interface.clear_stdout_buffer
        interface.flush
        interface.stdout_buffer.should be_empty
      end

      it "prints last sequence" do
        interface = create_interface
        interface.background 0, 0, 41, 33, 29
        interface.foreground 0, 1, 25, 57, 11
        interface.flush
        interface.clear_stdout_buffer

        interface.background 2, 1, 12, 23, 34
        interface.flush
        interface.stdout_buffer.should eq("\x1b[2;3H\e[48;2;12;23;34m \e[0m\e[3;4H\n")
      end
    end
  end

  describe "#hide" do
    context "with Color" do
      it "disables output" do
        interface = create_interface
        interface.hide
        interface.background 0, 0, :red
        interface.stdout_buffer.should be_empty
        interface.flush
        interface.stdout_buffer.should be_empty
      end
    end

    context "with RGBColor" do
      it "disables output" do
        interface = create_interface
        interface.hide
        interface.background 0, 0, 12, 23, 34
        interface.stdout_buffer.should be_empty
        interface.flush
        interface.stdout_buffer.should be_empty
      end
    end
  end

  describe "#show" do
    context "with Color" do
      it "enables output" do
        interface = create_interface
        interface.hide
        interface.background 0, 0, :red
        interface.stdout_buffer.should be_empty
        interface.show
        interface.flush
        interface.stdout_buffer.should be_empty
        interface.background 0, 0, :red
        interface.stdout_buffer.should be_empty
        interface.flush
        interface.stdout_buffer.should_not be_empty
      end
    end

    context "with RGBColor" do
      it "enables output" do
        interface = create_interface
        interface.hide
        interface.background 0, 0, 12, 23, 34
        interface.stdout_buffer.should be_empty
        interface.show
        interface.flush
        interface.stdout_buffer.should be_empty
        interface.background 0, 0, 12, 23, 34
        interface.stdout_buffer.should be_empty
        interface.flush
        interface.stdout_buffer.should_not be_empty
      end
    end
  end
end
