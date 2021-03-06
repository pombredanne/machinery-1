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

require_relative "spec_helper"

describe Machinery::ExportTask do
  capture_machinery_output
  include FakeFS::SpecHelpers

  let(:exporter) {
    double(
      name: "kiwi",
      export_name: "name-type",
      system_description: create_test_description(
        scopes: ["os"], extracted_scopes: ["unmanaged_files"]
      )
    )
  }
  subject { Machinery::ExportTask.new(exporter) }

  let(:exporter_autoyast) {
    double(
      name: "autoyast",
      export_name: "no-extracted-files",
      system_description: create_test_description(
        scopes: ["os", "changed_config_files", "unmanaged_files"]
      )
    )
  }

  before(:each) do
    FakeFS::FileSystem.clone(File.join(Machinery::ROOT, "export_helpers"))
    allow(Machinery::JsonValidator).to receive(:new).and_return(double(validate: []))
  end

  describe "#export" do
    it "writes the export" do
      expect(exporter).to receive(:write).with("/bar/name-type")
      subject.export("/bar", {})
      expect(captured_machinery_output).to include("Exported to '/bar/name-type'.")
    end

    it "shows the unmanaged file filters at the beginning" do
      allow(exporter).to receive(:write)
      expected_output = <<-EOF
Unmanaged files following these patterns are not exported:
var/lib/rpm/*
EOF
      subject.export("/bar", {})
      expect(captured_machinery_output).to include(expected_output)
    end

    it "raises a known error when a non-writable directory is given" do
      allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES)
      output_dir = "/foo"
      expect {
        subject.export(File.join(output_dir, "name"), force: false)
      }.to raise_error(Machinery::Errors::ExportFailed, /Permission denied/)
    end

    it "raises a known error if files are not extracted" do
      expect {
        Machinery::ExportTask.new(exporter_autoyast).export("/foo", {})
      }.to raise_error(
        Machinery::Errors::MissingExtractedFiles, /files weren't extracted during inspection/
      )
    end

    describe "when the output directory already exists" do
      let(:output_dir) { "/foo" }
      let(:export_dir) { "/foo/name-type" }
      let(:content) { "/foo/name-type/bar" }

      before(:each) do
        FileUtils.mkdir_p(export_dir)
        FileUtils.touch(content)
      end

      it "raises an error when --force is not given" do
        expect {
          subject.export(output_dir, force: false)
        }.to raise_error(Machinery::Errors::ExportFailed)
      end

      it "overwrites existing directory when --force is given" do
        expect(exporter).to receive(:write).with(export_dir)
        expect {
          subject.export(output_dir, force: true)
        }.to_not raise_error

        expect(File.exist?(content)).to be(false)
        expect(captured_machinery_output).to include("Exported to '#{export_dir}'.")
      end
    end
  end
end
