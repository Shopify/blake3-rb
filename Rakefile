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

  old_gemspec = File.read("blake3-rb.gemspec")
  new_gemspec = old_gemspec.gsub("version = \"#{old_version}\"", "version = \"#{new_version}\"")

  File.write("blake3-rb.gemspec", new_gemspec)
  diff = %x(git diff blake3-rb.gemspec)

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
    File.write("blake3-rb.gemspec", old_gemspec)
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
