# encoding:utf-8

# Copyright (c) 2013-2016 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

require_relative "go"

# This class is used in the machinery-helper/Rakefile to build the helper
class HelperBuilder
  def initialize(helper_dir)
    @helper_dir = helper_dir
    @git_revision_file = File.join(helper_dir, "..", ".git_revision")
    @go_version_file = File.join(helper_dir, "version.go")
    @go = Go.new
  end

  def run_build
    return false unless @go.available?

    # handle changed branches (where go files are older than the helper)
    if runs_in_git? && (changed_revision? || !File.exist?(@go_version_file))
      write_go_version_file
      if build_machinery_helper
        write_git_revision_file
        return true
      else
        return false
      end
    end

    @go.archs.each do |arch|
      next if FileUtils.uptodate?(
        File.join(@helper_dir, "machinery-helper-#{arch}"),
        Dir.glob(File.join(@helper_dir, "*.go"))
      )
      return build_machinery_helper
    end
    true
  end

  def write_go_version_file
    file = <<-EOF
// This is a generated file and shouldn't be changed

package main

const VERSION = "#{git_revision}"
    EOF
    File.write(@go_version_file, file)
  end

  def build_machinery_helper
    FileUtils.rm_f(Dir.glob(File.join(@helper_dir, "machinery-helper*")))
    Dir.chdir(@helper_dir) do
      puts("Building machinery-helper binaries")
      if @go.build
        true
      else
        STDERR.puts("Error: Building of the machinery-helper failed!")
        false
      end
    end
  end

  def runs_in_git?
    Dir.exist?(File.join(@helper_dir, "..", ".git")) && system("which git > /dev/null 2>&1")
  end

  def write_git_revision_file
    File.write(@git_revision_file, git_revision)
  end

  def changed_revision?
    if File.exist?(@git_revision_file)
      old_revision = File.read(@git_revision_file)
    else
      old_revision = "unknown"
    end
    git_revision != old_revision
  end

  private

  def git_revision
    `git rev-parse HEAD`.chomp
  end
end
