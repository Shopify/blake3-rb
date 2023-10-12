# frozen_string_literal: true

require "rake/testtask"
require "bundler/gem_tasks"

GEMSPEC = Bundler.load_gemspec("digest-blake3.gemspec")

Rake::Task["release"].clear

desc "Trigger publishing of a new release"
task :release do
  abort("ERROR: uncommited changes") unless system("git diff --exit-code")

  old_version = GEMSPEC.version.to_s
  print "Enter new version (current is #{old_version}): "
  new_version = STDIN.gets.strip
  new_git_tag = "v#{new_version}"

  abort("ERROR: #{GEMSPEC.version} tag already exists") if system("git rev-parse #{new_git_tag}")

  old_gemspec = File.read("digest-blake3.gemspec")
  new_gemspec = old_gemspec.gsub("version = \"#{old_version}\"", "version = \"#{new_version}\"")

  File.write("digest-blake3.gemspec", new_gemspec)
  diff = `git diff digest-blake3.gemspec`

  puts "Diff:\n#{diff}"
  print "Does this look good? (y/n): "

  if STDIN.gets.strip == "y"
    sh "bundle"
    sh "git commit -am \"Bump version to #{new_git_tag}\""
    sh "git tag #{new_git_tag}"
    sh "git push"
    sh "git push --tags"
  else
    File.write("digest-blake3.gemspec", old_gemspec)
    puts "Aborting release"
  end
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
