class String
  def remove_xml_declaration
    self.gsub( /\<\?xml.*\?\>/, '' )
  end
end

puts "<?xml foiwjefowifj ?>sdkfjldkfj".remove_xml_declaration