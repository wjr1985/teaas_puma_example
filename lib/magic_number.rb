module MagicNumber
  def self.gif?(header)
    header == "GIF8"
  end

  def self.jpg?(header)
    header == "\xff\xd8\xff\xe0"
  end

  def self.png?(header)
    header == "\x89\x50\x4e\x47"
  end
end
