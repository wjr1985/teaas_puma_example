module MagicNumber
  def self.gif?(header)
    header.force_encoding("UTF-8") == "GIF8"
  end

  def self.jpg?(header)
    header.force_encoding("UTF-8") == "\xff\xd8\xff\xe0"
  end

  def self.png?(header)
    header.force_encoding("UTF-8") == "\x89\x50\x4e\x47"
  end
end
