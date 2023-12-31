# frozen_string_literal: true

require "test_helper"
require "base64"
require "tempfile"

module Blake3
  class DigestTest < Minitest::Test
    def test_hasher_hexdigest_returns_expected_value_for_non_empty_string
      hasher = Digest::Blake3.new
      hasher.update("ho")
      hasher.update("ge")
      result = hasher.hexdigest

      assert_equal("77412ee5089c51bcf6568c621aa3a83081a6477b576ff19bfb31e9d657acd91a", result)
    end

    def test_hasher_hexdigest_returns_expected_value_for_empty_string
      hasher = Digest::Blake3.new
      hasher.update("")
      result = hasher.hexdigest

      assert_equal("af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262", result)
    end

    def test_hasher_hexdigest_bang_resets_state
      hasher = Digest::Blake3.new
      hasher.update("hoge")
      result = hasher.hexdigest!
      hasher.update("hoge")

      assert_equal("77412ee5089c51bcf6568c621aa3a83081a6477b576ff19bfb31e9d657acd91a", result)
    end

    def test_hasher_digest_returns_bytestring
      hasher = Digest::Blake3.new
      hasher.update("ho")
      hasher.update("ge")
      result = hasher.digest

      assert_equal("d0Eu5QicUbz2VoxiGqOoMIGmR3tXb/Gb+zHp1les2Ro=", Base64.strict_encode64(result))
    end

    def test_digest_bang_resets_state
      hasher = Digest::Blake3.new
      hasher.update("hoge")
      result = hasher.digest!
      hasher.update("hoge")

      assert_equal("d0Eu5QicUbz2VoxiGqOoMIGmR3tXb/Gb+zHp1les2Ro=", Base64.strict_encode64(result))
    end

    def test_base64digest_returns_expected_value
      hasher = Digest::Blake3.new
      hasher.update("ho")
      hasher.update("ge")
      result = hasher.base64digest

      assert_equal("d0Eu5QicUbz2VoxiGqOoMIGmR3tXb/Gb+zHp1les2Ro=", result)
    end

    def test_base64digest_bang_resets_state
      hasher = Digest::Blake3.new
      hasher.update("hoge")
      result = hasher.base64digest!
      hasher.update("hoge")

      assert_equal("d0Eu5QicUbz2VoxiGqOoMIGmR3tXb/Gb+zHp1les2Ro=", result)
    end

    def test_inspect
      hasher = Digest::Blake3.new
      hasher.update("hoge")

      assert_equal(
        "#<Digest::Blake3: 77412ee5089c51bcf6568c621aa3a83081a6477b576ff19bfb31e9d657acd91a>",
        hasher.inspect,
      )
    end

    def test_initialize_from_file
      Tempfile.create("blake3-test") do |f|
        f.sync = true
        f.write("hoge")
        hasher = Digest::Blake3.new.file(f.path)

        assert_equal("77412ee5089c51bcf6568c621aa3a83081a6477b576ff19bfb31e9d657acd91a", hasher.hexdigest)
      end
    end

    def test_clones_the_inner_state
      hasher = Digest::Blake3.new
      hasher.update("ho")
      cloned_hasher = hasher.clone
      cloned_hasher << "ge"

      assert_equal("3a7e0ef8a3a0bb01995763bbba2b7a97ecfe5a0b5f8c4e42cc3a53b86617597f", hasher.hexdigest)
      assert_equal("77412ee5089c51bcf6568c621aa3a83081a6477b576ff19bfb31e9d657acd91a", cloned_hasher.hexdigest)
    end

    def test_reset_resets_the_inner_state_and_returns_self
      hasher = Digest::Blake3.new
      old_object_id = hasher.object_id
      hasher.update("ho")
      hasher.reset
      new_object_id = hasher.object_id
      empty_digest = "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262"

      assert_equal(empty_digest, hasher.hexdigest)
      assert_equal(old_object_id, new_object_id)
    end

    def test_block_length
      assert_equal(64, Digest::Blake3.new.block_length)
    end

    def test_digest_length
      assert_equal(32, Digest::Blake3.new.digest_length)
    end

    def test_equality_with_other_digest
      digest_one = Digest::Blake3.new
      digest_two = Digest::Blake3.new
      digest_one.update("hoge")
      digest_two.update("hoge")

      assert_equal(digest_one, digest_two)
      digest_two.update("fuga")
      refute_equal(digest_one, digest_two)
    end

    def test_equality_with_string
      assert_equal(
        Digest::Blake3.new.update("hoge"),
        "77412ee5089c51bcf6568c621aa3a83081a6477b576ff19bfb31e9d657acd91a",
      )
      refute_equal(Digest::Blake3.new.update("baz"), "invalid")
    end
  end
end
