# frozen_string_literal: true

class TestBlake3 < Minitest::Test
  def test_hexdigest
    assert_equal("77412ee5089c51bcf6568c621aa3a83081a6477b576ff19bfb31e9d657acd91a", Blake3.hexdigest("hoge"))
  end

  def test_digest
    assert_equal("d0Eu5QicUbz2VoxiGqOoMIGmR3tXb/Gb+zHp1les2Ro=", Base64.strict_encode64(Blake3.digest("hoge")))
  end

  def test_base64digest
    assert_equal("d0Eu5QicUbz2VoxiGqOoMIGmR3tXb/Gb+zHp1les2Ro=", Blake3.base64digest("hoge"))
  end

  def test_file
    Tempfile.create("blake3-test") do |f|
      f.sync = true
      f.write("hoge")
      hasher = Blake3.file(f.path)

      assert_equal("77412ee5089c51bcf6568c621aa3a83081a6477b576ff19bfb31e9d657acd91a", hasher.hexdigest)
    end
  end
end
