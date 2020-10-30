module Tilerender

	enum Color : UInt32 # Future: complete 24-bit RGB palette support
		Empty

		Black
		Blue
		Cyan
		Gray
		Green
		Lime
		Magenta
		Maroon
		Navy
		Orange
		Pink
		Purple
		Red
		Silver
		Teal
		White
		Yellow
	end

	record RGBColor, red : UInt8, green : UInt8, blue : UInt8

	alias BaseColor = Color | RGBColor

end
