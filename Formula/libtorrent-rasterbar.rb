class LibtorrentRasterbar < Formula
  desc "C++ bittorrent library with Python bindings"
  homepage "https://www.libtorrent.org/"
  url "https://github.com/arvidn/libtorrent/releases/download/libtorrent-1_2_1/libtorrent-rasterbar-1.2.1.tar.gz"
  sha256 "cceba9842ec7d87549cee9e39d95fd5ce68b0eb9b314a2dd0d611cfa9798762d"

  bottle do
    cellar :any
    sha256 "01861883a907e1a1dad65a7a7c8172bff6fcd35ed137e07d62ce80a39fd768c3" => :mojave
    sha256 "acdcf6ddc140f4ccf423b8238b61f7caa6908e0de22287f2c6e42cadfb318ea1" => :high_sierra
    sha256 "8e6bd07ced569f546d324c2ec9832ac09135bf32e9f382c862d0a41215f69651" => :sierra
  end

  head do
    url "https://github.com/arvidn/libtorrent.git"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "boost"
  depends_on "boost-python3"
  depends_on "cmake" => :build
  depends_on "openssl"
  depends_on "python"

  def install
    args = std_cmake_args + %W[
      -DCMAKE_BUILD_TYPE=Release
      -Dpython-bindings=ON
      -DCMAKE_CXX_STANDARD=11
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -Dboost-python-module-name=python37
    ]

    # CMake picks up the system's python dylib, even if we have a brewed one.
    py3ver = Language::Python.major_minor_version "python3"
    py3prefix = Formula["python3"].opt_frameworks/"Python.framework/Versions/#{py3ver}"

    args << "-DPYTHON_EXECUTABLE=#{py3prefix}/bin/python3"
    args << "-DPYTHON_LIBRARY=#{py3prefix}/lib/libpython#{py3ver}.dylib"
    args << "-DPYTHON_INCLUDE_DIR=#{py3prefix}/include/python#{py3ver}m"

    # CMake picks up boost-python instead of boost-python3
    args << "-DBoost_INCLUDE_DIR=#{Formula["boost"].opt_include}"
    args << "-DBoost_LIBRARY_DIRS=#{Formula["boost"].opt_lib}:#{Formula["boost-python3"].opt_lib}"

    mkdir "builddir" do
      system "cmake", "..", *args
      system "make", "install"
    end

    libexec.install "examples"
  end

  test do
    system ENV.cxx, "-std=c++11", "-I#{Formula["boost"].include}/boost",
                    "-L#{lib}", "-ltorrent-rasterbar",
                    "-L#{Formula["boost"].lib}", "-lboost_system",
                    "-framework", "SystemConfiguration",
                    "-framework", "CoreFoundation",
                    libexec/"examples/make_torrent.cpp", "-o", "test"
    system "./test", test_fixtures("test.mp3"), "-o", "test.torrent"
    assert_predicate testpath/"test.torrent", :exist?
  end
end
