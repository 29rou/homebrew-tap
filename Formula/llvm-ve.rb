class LlvmVe < Formula
  desc "LLVM for NEC SX-Aurora VE"
  homepage "https://github.com/sx-aurora-dev/llvm-project"
  url "https://github.com/sx-aurora-dev/llvm-project/archive/refs/tags/llvm-ve-1.20.0.tar.gz"
  sha256 "500e8617887e57c09a047b61083431eaadbb073f78e8a6ef9f84285baf07abc5"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/sx-aurora-dev/llvm-project.git", branch: "develop"
  # depends_on "cmake" => :build
  
  # Clang cannot find system headers if Xcode CLT is not installed
  pour_bottle? only_if: :clt_installed

  keg_only :provided_by_macos

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  #uses_from_macos "libedit"
  #uses_from_macos "libffi", since: :catalina
  uses_from_macos "libxml2"
  #uses_from_macos "ncurses"
  uses_from_macos "zlib"
  def install

    targets = %w[
      VE
      X86
    ]
    # Apple's libstdc++ is too old to build LLVM
    ENV.libcxx if ENV.compiler == :clang

    # compiler-rt has some iOS simulator features that require i386 symbols
    # I'm assuming the rest of clang needs support too for 32-bit compilation
    # to work correctly, but if not, perhaps universal binaries could be
    # limited to compiler-rt. llvm makes this somewhat easier because compiler-rt
    # can almost be treated as an entirely different build from llvm.
    ENV.permit_arch_flags

    # we install the lldb Python module into libexec to prevent users from
    # accidentally importing it with a non-Homebrew Python or a Homebrew Python
    # in a non-default prefix. See https://lldb.llvm.org/resources/caveats.html
    args = %W[
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DPACKAGE_VENDOR=#{tap.user}
      -DBUG_REPORT_URL=#{tap.issues_url}
      -DCLANG_VENDOR_UTI=org.#{tap.user.downcase}.clang
      -DCMAKE_BUILD_TYPE=Release
      -DBUILD_SHARED_LIBS=OFF
      -DLLVM_ENABLE_FFI=OFF
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLDB_ENABLE_PYTHON=OFF
    ]
    args_clang = %W[
      -DLLVM_ENABLE_PROJECTS="clang"
      -DLLVM_TARGETS_TO_BUILD=#{targets.join(";")}
    ]
    args_compiler_rt = %W[
      -DLLVM_ENABLE_PROJECTS="compiler-rt"
      -DCOMPILER_RT_BUILD_BUILTINS=ON
      -DCOMPILER_RT_BUILD_SANITIZERS=OFF
      -DCOMPILER_RT_BUILD_XRAY=OFF
      -DCOMPILER_RT_BUILD_LIBFUZZER=OFF
      -DCOMPILER_RT_BUILD_PROFILE=OFF
      -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON
      -DCMAKE_CXX_FLAGS="-nostdlib"
      -DCMAKE_CXX_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize" 
      -DCMAKE_C_FLAGS="-nostdlib" 
      -DCMAKE_C_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize" 
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_C_COMPILER_TARGET="ve-linux"
      -DCMAKE_ASM_COMPILER_TARGET="ve-linux"
      -DCMAKE_C_COMPILER=#{prefix}/bin/clang
      -DCMAKE_CXX_COMPILER=#{prefix}/bin/clang++
      -DCMAKE_AR=#{prefix}/bin/llvm-ar
      -DCMAKE_RANLIB=#{prefix}/bin/llvm-ranlib
      -DLLVM_CONFIG_PATH=#{prefix}/bin/llvm-config
    ]
    args_libunwind = %W[
      -DLLVM_ENABLE_PROJECTS="libunwind"
      -DLIBUNWIND_TARGET_TRIPLE="ve-linux"
      -DCMAKE_CXX_COMPILER_TARGET="ve-linux"
      -DLLVM_ENABLE_LIBCXX=ON
      -DCMAKE_CXX_FLAGS="-nostdlib" 
      -DCMAKE_CXX_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize" 
      -DCMAKE_C_FLAGS="-nostdlib" 
      -DCMAKE_C_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize"
      -DCMAKE_C_COMPILER=#{prefix}/bin/clang
      -DCMAKE_CXX_COMPILER=#{prefix}/bin/clang++
      -DCMAKE_AR=#{prefix}/bin/llvm-ar
      -DCMAKE_RANLIB=#{prefix}/bin/llvm-ranlib
      -DLLVM_CONFIG_PATH=#{prefix}/bin/llvm-config
    ]
    args_libcxxabi = %W[
      -DLLVM_ENABLE_PROJECTS="libcxxabi"
      -DLIBUNWIND_TARGET_TRIPLE="ve-linux"
      -DCMAKE_CXX_COMPILER_TARGET="ve-linux"
      -DLLVM_ENABLE_LIBCXX=ON
      -DLIBCXXABI_USE_COMPILER_RT=True
      -DLIBCXXABI_HAS_NOSTDINCXX_FLAG=True
      -DCMAKE_CXX_FLAGS="-nostdlib" 
      -DCMAKE_CXX_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize" 
      -DCMAKE_C_FLAGS="-nostdlib" 
      -DCMAKE_C_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize"
      -DCMAKE_C_COMPILER=#{prefix}/bin/clang
      -DCMAKE_CXX_COMPILER=#{prefix}/bin/clang++
      -DCMAKE_AR=#{prefix}/bin/llvm-ar
      -DCMAKE_RANLIB=#{prefix}/bin/llvm-ranlib
      -DLLVM_CONFIG_PATH=#{prefix}/bin/llvm-config
    ]
    args_libcxx = %W[
      -DLLVM_ENABLE_PROJECTS="libcxx"
      -DLIBUNWIND_TARGET_TRIPLE="ve-linux"
      -DCMAKE_CXX_COMPILER_TARGET="ve-linux"
      -DCMAKE_CXX_FLAGS="-nostdlib" 
      -DCMAKE_CXX_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize" 
      -DCMAKE_C_FLAGS="-nostdlib" 
      -DCMAKE_C_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize"
      -DCMAKE_C_COMPILER=#{prefix}/bin/clang
      -DCMAKE_CXX_COMPILER=#{prefix}/bin/clang++
      -DCMAKE_AR=#{prefix}/bin/llvm-ar
      -DCMAKE_RANLIB=#{prefix}/bin/llvm-ranlib
      -DLLVM_CONFIG_PATH=#{prefix}/bin/llvm-config
    ]
    args_openmp = %W[
      -DLLVM_ENABLE_PROJECTS="openmp"
      -DLIBUNWIND_TARGET_TRIPLE="ve-linux"
      -DCMAKE_CXX_COMPILER_TARGET="ve-linux"
      -DCMAKE_CXX_FLAGS="" 
      -DCMAKE_CXX_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize -mllvm -combiner-use-vector-store=false" 
      -DCMAKE_C_FLAGS="" 
      -DCMAKE_C_FLAGS_RELEASE="-O3 -fno-vectorize -fno-slp-vectorize -mllvm -combiner-use-vector-store=false" 
      -DLIBOMP_ARCH="ve"
      -DCMAKE_C_COMPILER=#{prefix}/bin/clang
      -DCMAKE_CXX_COMPILER=#{prefix}/bin/clang++
      -DCMAKE_AR=#{prefix}/bin/llvm-ar
      -DCMAKE_RANLIB=#{prefix}/bin/llvm-ranlib
      -DLLVM_CONFIG_PATH=#{prefix}/bin/llvm-config
    ]

    clangpath = buildpath

    # Now, we can build.
    mkdir clangpath/"clang-build" do
      system "cmake", "-S", "../llvm" ,"-G", "Ninja", "-B", "./", *(std_cmake_args + args + args_clang)
      # Workaround for CMake Error: failed to create symbolic link
      ENV.deparallelize if Hardware::CPU.arm?
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
      #system "cmake", "--build", ".", "--target", "install-xcode-toolchain" if MacOS::Xcode.installed?
    end
    
    compiler_rtpath = buildpath

    mkdir compiler_rtpath/"compiler_rtpath-build" do
      system "cmake", "-S", "../llvm", "-G", "Ninja", "-B", "./", *(std_cmake_args + args + args_compiler_rt )
      # Workaround for CMake Error: failed to create symbolic link
      ENV.deparallelize if Hardware::CPU.arm?
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
      #system "cmake", "--build", ".", "--target", "install-xcode-toolchain" if MacOS::Xcode.installed?
    end

    libunwindpath = buildpath

    mkdir libunwindpath/"libunwindpath-build" do
      system "cmake", "-S", "../llvm", "-G", "Ninja", "-B", "./", *(std_cmake_args + args + args_libunwind )
      # Workaround for CMake Error: failed to create symbolic link
      ENV.deparallelize if Hardware::CPU.arm?
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
      #system "cmake", "--build", ".", "--target", "install-xcode-toolchain" if MacOS::Xcode.installed?
    end

    libcxxabipath = buildpath

    mkdir libcxxabipath/"libcxxabipath-build" do
      system "cmake", "-S", "../llvm", "-G", "Ninja", "-B", "./", *(std_cmake_args + args + args_libcxxabi )
      # Workaround for CMake Error: failed to create symbolic link
      ENV.deparallelize if Hardware::CPU.arm?
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
      #system "cmake", "--build", ".", "--target", "install-xcode-toolchain" if MacOS::Xcode.installed?
    end

    libcxxpath = buildpath

    mkdir libcxxpath/"libcxxpath-build" do
      system "cmake", "-S", "../llvm", "-G", "Ninja", "-B", "./", *(std_cmake_args + args + args_libcxx )
      # Workaround for CMake Error: failed to create symbolic link
      ENV.deparallelize if Hardware::CPU.arm?
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
      #system "cmake", "--build", ".", "--target", "install-xcode-toolchain" if MacOS::Xcode.installed?
    end

    openmppath = buildpath

    mkdir openmppath/"openmppath-build" do
      system "cmake", "-S", "../llvm", "-G", "Ninja", "-B", "./", *(std_cmake_args + args + args_openmp )
      # Workaround for CMake Error: failed to create symbolic link
      ENV.deparallelize if Hardware::CPU.arm?
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
      #system "cmake", "--build", ".", "--target", "install-xcode-toolchain" if MacOS::Xcode.installed?
    end

    on_macos do
      # Install versioned symlink, or else `llvm-config` doesn't work properly
      lib.install_symlink "libLLVM.dylib" => "libLLVM-#{version.major}.dylib" unless build.head?
    end

  end

  def caveats
    <<~EOS
      To use the bundled libc++ please add the following LDFLAGS:
        LDFLAGS="-L#{opt_lib} -Wl,-rpath,#{opt_lib}"
    EOS
  end
  test do
    assert_equal prefix.to_s, shell_output("#{bin}/llvm-config --prefix").chomp
    assert_equal "-lLLVM-#{version.major}", shell_output("#{bin}/llvm-config --libs").chomp
    assert_equal (lib/shared_library("libLLVM-#{version.major}")).to_s,
                 shell_output("#{bin}/llvm-config --libfiles").chomp
  end
end