# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PrerequisiteCascadesHelper do
  describe "#format_prerequisite_period" do
    it "formats start and end" do
      period = Date.new(2026, 1, 1)..Date.new(2026, 3, 31)

      expect(helper.format_prerequisite_period(period)).to eq "01.01.2026 – 31.03.2026"
    end

    it "formats an open end" do
      period = Date.new(2026, 1, 1)..nil

      expect(helper.format_prerequisite_period(period)).to eq "01.01.2026 – offen"
    end
  end

  describe "#prerequisite_cascade_resubmit_fields" do
    def resubmit_fields(request_parameters)
      allow(helper.request).to receive(:request_parameters).and_return(request_parameters)
      Capybara::Node::Simple.new(helper.prerequisite_cascade_resubmit_fields)
        .all("input[type=hidden]", visible: false)
        .map { |input| [input[:name], input[:value]] }
    end

    it "renders a field per scalar value" do
      expect(resubmit_fields("ids" => "1,2")).to eq [%w[ids 1,2]]
    end

    it "renders nested hashes with bracket notation" do
      params = {"role" => {"end_on" => "2026-12-31", "types" => {"Group::Mitglieder" => "1"}}}

      expect(resubmit_fields(params)).to eq [
        ["role[end_on]", "2026-12-31"],
        ["role[types][Group::Mitglieder]", "1"]
      ]
    end

    it "renders a field per array element" do
      expect(resubmit_fields("ids" => %w[1 2])).to eq [["ids[]", "1"], ["ids[]", "2"]]
    end

    it "renders arrays nested in hashes" do
      expect(resubmit_fields("filters" => {"tag" => %w[a b]})).to eq [
        ["filters[tag][]", "a"],
        ["filters[tag][]", "b"]
      ]
    end

    it "skips the parameters the confirmation form sets itself" do
      params = {"authenticity_token" => "token", "_method" => "delete", "ids" => "1"}

      expect(resubmit_fields(params)).to eq [%w[ids 1]]
    end

    it "escapes values" do
      allow(helper.request).to receive(:request_parameters).and_return("label" => "<b>")

      expect(helper.prerequisite_cascade_resubmit_fields).not_to include("<b>")
      expect(resubmit_fields("label" => "<b>")).to eq [["label", "<b>"]]
    end

    it "renders fields without ids" do
      allow(helper.request).to receive(:request_parameters).and_return("role" => {"end_on" => "x"})

      expect(helper.prerequisite_cascade_resubmit_fields).not_to include("id=")
    end
  end
end
