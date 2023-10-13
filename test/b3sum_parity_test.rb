# frozen_string_literal: true

require "test_helper"

class B3SumParityTest < Minitest::Test
  %x(git ls-files).split("\n").sort.each_with_index do |file, i|
    next unless File.exist?(file)

    slug = file.gsub(/[^a-z0-9]/i, "_").downcase

    define_method("test_#{slug}_#{i}") do
      expected_result = %x(b3sum --no-names #{file}).strip
      string_result = Digest::Blake3.hexdigest(File.binread(file))
      file_result = Digest::Blake3.file(file).hexdigest

      assert_equal expected_result, string_result
      assert_equal expected_result, file_result
    end
  end
end
