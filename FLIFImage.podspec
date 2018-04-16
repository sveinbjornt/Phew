Pod::Spec.new do |s|
    s.name         = "FLIFImage"
    s.version      = "1.0.2"
    s.summary      = "Objective-C wrapper for libflif"
    s.description  = "Objective-C class to easily read images in the FLIF format via libflif."
    s.homepage     = "http://github.com/sveinbjornt/Phew"
    s.license      = { :type => 'BSD' }
    s.author       = { "Sveinbjorn Thordarson" => "sveinbjorn@sveinbjorn.org" }
    s.osx.deployment_target = "10.10"
    s.source       = { :git => "https://github.com/sveinbjornt/Phew.git", :tag => "1.0.2" }
    s.source_files = "FLIFImage/FLIFImage.{h,m}", "FLIFImage/*"
    s.exclude_files = ""
    s.public_header_files = "FLIFImage/*.h"
    s.framework    = "AppKit"
    s.requires_arc = true
    s.vendored_libraries = "libs/libflif.dylib", "libs/libpng.dylib"
end
