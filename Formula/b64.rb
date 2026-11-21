class B64 < Formula
  desc "Encode, decode and validate Base64 from the command line"
  homepage "https://base64hub.com/cli/"
  version "1.0.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/base64hub-com/base64hub-cli/releases/download/v1.0.0/b64_darwin_arm64.tar.gz"
      sha256 "b4589afa565dae6ca3934c6ff4b650f77a9a116ce233d5ed0fe5338602f55ea2"
    end
    on_intel do
      url "https://github.com/base64hub-com/base64hub-cli/releases/download/v1.0.0/b64_darwin_amd64.tar.gz"
      sha256 "18f03e05e5065f190de0e33a69b00ec78ed906a9279981ef0f3f2e53f0d36eb7"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/base64hub-com/base64hub-cli/releases/download/v1.0.0/b64_linux_arm64.tar.gz"
      sha256 "70900e6cad4b5dfa59a68cf13353a79114d79dd4628651c6a48064a0a3525df8"
    end
    on_intel do
      url "https://github.com/base64hub-com/base64hub-cli/releases/download/v1.0.0/b64_linux_amd64.tar.gz"
      sha256 "a5af8b8b5eca6f8146778dbd72589f15eb7284835f0dee97ada9271c6cfe2a59"
    end
  end

  def install
    bin.install "b64"
  end

  test do
    assert_equal "b64 #{version}", shell_output("#{bin}/b64 --version").strip
    assert_equal "SGVsbG8sIGh1YiE=", shell_output("#{bin}/b64 'Hello, hub!'").strip
  end
end
