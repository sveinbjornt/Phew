Pod::Spec.new do |s|
    s.name         = "FLIFImage"
    s.version      = "1.0.0"
    s.summary      = "Objective-C wrapper for libflif"
    s.description  = "Objective-C class to easily read images in the FLIF format via libflif."
    s.homepage     = "http://github.com/sveinbjornt/Phew"
    s.license      = { :type => 'BSD' }
    s.author       = { "Sveinbjorn Thordarson" => "sveinbjornt@gmail.com" }
    s.osx.deployment_target = "10.10"
    s.source       = { :git => "https://github.com/sveinbjornt/Phew.git", :tag => "1.0.0" }
    s.source_files = "FLIFImage/FLIFImage.{h,m}", "FLIFImage/FLIF/*", "FLIFImage/*.hpp", "FLIFImage/image/*.hpp"
    s.exclude_files = ""
    s.public_header_files = "FLIFImage/FLIFImage.h", "FLIFImage/*.hpp", "FLIFImage/image/*.hpp", "FLIFImage/FLIF/*"
    s.framework    = "AppKit"
    s.requires_arc = true
    s.vendored_libraries = "libs/libflif.dylib", "libs/libpng.dylib"
s.library = 'c++'
s.xcconfig = {
'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
'CLANG_CXX_LIBRARY' => 'libc++'
}
end