# frozen_string_literal: true

require "rake/testtask"

GEMSPEC = Bundler.load_gemspec("digest-blake3.gemspec")

desc "Build source gem"
task :build do
  FileUtils.mkdir_p("pkg")
  sh "gem build #{GEMSPEC.name}.gemspec --output pkg/#{GEMSPEC.name}-#{GEMSPEC.version}.gem"
end

desc "Upload gems to rubygems.org"
task :release do
  sh "scripts/pre_release"
  current_tag = %x(git describe --tags --abbrev=0).strip
  sh "scripts/download_github_release_artifacts Shopify/digest-blake3 #{current_tag}"
  Dir["pkg/*.gem"].each { |gem| sh "gem push #{gem}" }
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/**/*_test.rb"]
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  # Optional dependency
end

require "rb_sys/extensiontask"

RbSys::ExtensionTask.new("blake3_ext", GEMSPEC) do |ext|
  ext.lib_dir = "lib/digest/blake3"
end

task default: [:compile, :test, :rubocop]
