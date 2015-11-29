Pod::Spec.new do |s|
  s.name             = "Thread"
  s.version          = "1.0.1"
  s.summary          = "A simple wrapper on NSThread to run blocks on exactly the same thread. It’s guaranteed First-In-First-Out (FIFO)."
  s.homepage         = "https://github.com/duemunk/Thread"
  s.license          = 'MIT'
  s.author           = { "Tobias Due Munk" => "tobias@developmunk.dk" }
  s.osx.deployment_target = "10.10"
  s.ios.deployment_target = "8.0"
  s.tvos.deployment_target = "9.0"
  s.source           = { :git => "https://github.com/duemunk/Thread.git", :tag => s.version.to_s }
  s.source_files = 'Source/*.swift'
  s.requires_arc = true
  s.frameworks = 'Foundation'
end
