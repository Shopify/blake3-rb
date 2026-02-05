# frozen_string_literal: true

require "rake/testtask"
require "bundler/gem_tasks"

GEMSPEC = Bundler.load_gemspec("blake3-rb.gemspec")

Rake::Task["release"].clear

desc "Trigger publishing of a new release"
task :release do
  abort("ERROR: uncommited changes") unless system("git diff --exit-code")

  old_version = GEMSPEC.version.to_s
  print "Enter new version (current is #{old_version}): "
  new_version = $stdin.gets.strip
  new_git_tag = "v#{new_version}"

  abort("ERROR: #{GEMSPEC.version} tag already exists") if system("git rev-parse #{new_git_tag}")

  version_file = "lib/digest/blake3/version.rb"
  old_content = File.read(version_file)
  new_content = old_content.gsub("VERSION = \"#{old_version}\"", "VERSION = \"#{new_version}\"")

  File.write(version_file, new_content)
  diff = %x(git diff #{version_file})

  puts "Diff:\n#{diff}"
  print "Does this look good? (y/n): "

  if $stdin.gets.strip == "y"
    sh "bundle"
    sh "git commit -am \"Bump version to #{new_git_tag}\""
    sh "git tag #{new_git_tag}"
    sh "git push"
    sh "git push --tags"

    sleep 3

    runs = %x(gh run list -w release -e push -b #{new_git_tag} --json=databaseId --jq '.[].databaseId')
    runs = runs.strip.split("\n")

    if runs.empty?
      warn("WARN: no release runs found")
    elsif runs.length > 1
      warn("WARN: multiple release runs found")
    else
      puts "Watching release run #{runs.first}, safe to Ctrl-C..."
      sleep 3
      system("gh run watch #{runs.first}")
      shipit_link = "https://shipit.shopify.io/shopify/blake3-rb/release"
      system("osascript -e 'display notification \"Release complete -> #{shipit_link}\" with title \"blake3-rb\"'")
      puts "Release complete, see #{shipit_link}"
    end
  else
    File.write(version_file, old_content)
    puts "Aborting release"
  end
end

desc "Run tests"
Rake::TestTask.new(:ruby_test) do |t|
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
  require "rake/extensiontask"

  Rake::ExtensionTask.new("blake3_ext", GEMSPEC) do |ext|
    ext.ext_dir = "ext/digest/blake3_ext"
    ext.lib_dir = "lib/digest/blake3"
  end
rescue LoadError
  warn("WARN: rake-compiler not installed, so no compile tasks will be defined")
end

desc "Run all tests"
task test: [:ruby_test]

task default: [:compile, :test, :rubocop]
