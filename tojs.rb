require "opal"

ruby_file = ARGV[0]

open("#{File.basename(ruby_file)}.js", "w") do |stream|
  builder = Opal::Builder.new
  builder.build_str(File.read(ruby_file), "(inline)")
  stream.puts builder.to_s
end
