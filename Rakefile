# frozen_string_literal: true

require "rake/testtask"
require "bundler/gem_tasks"

GEMSPEC = Bundler.load_gemspec("digest-blake3.gemspec")

desc "Publish git tag for current version"
task :tag do
  sh "bundle"

  abort("ERROR: uncommited changes") unless system("git diff --exit-code")
  abort("ERROR: #{GEMSPEC.version} tag already exists") if system("git rev-parse #{GEMSPEC.version}")

  sh "git tag #{GEMSPEC.version}"
  sh "git push"
  sh "git push --tags"
  puts "Tagged #{GEMSPEC.version}"
end

desc "Run tests"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/**/*_test.rb"]
end

begin
  require "rubocop/rake_task"

  RuboCop::RakeTask.new
rescue LoadError
  warn("WARN: rubocop not installed, so no lint tasks will be defined")
end

begin
  require "rb_sys/extensiontask"

  RbSys::ExtensionTask.new("blake3_ext", GEMSPEC) do |ext|
    ext.lib_dir = "lib/digest/blake3"
  end
rescue Errno::ENOENT
  warn("WARN: cargo not installed, so no compile tasks will be defined")
end

task default: [:compile, :test, :rubocop]
