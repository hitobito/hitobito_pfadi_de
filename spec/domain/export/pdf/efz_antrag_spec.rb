# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe Export::Pdf::EfzAntrag do
  let(:person) do
    Person.new(
      first_name: "Hans",
      last_name: "Muster",
      street: "Musterstrasse 1",
      zip_code: "10115",
      town: "Berlin",
      country: "DE",
      birthday: Date.new(1942, 1, 1),
      id: 12345
    )
  end

  let(:group) do
    Group::Stamm.new(
      id: 41,
      einsichtnahme_efz_durch_gruppe: false,
      name: "Geier Gruppe"
    )
  end

  let(:efz_verantwortliche_stelle) do
    Group::Stamm.new(
      id: 42,
      einsichtnahme_efz_durch_gruppe: true,
      name: "Adler Gruppe",
      street: "Gruppenstrasse 10",
      zip_code: "10117",
      town: "Berlin",
      country: "DE",
      email: "gruppe@example.com",
      phone_numbers_attributes: [{number: "+49 30 123 45 67"}]
    )
  end

  before do
    allow(group).to receive(:hierarchy).and_return([efz_verantwortliche_stelle, group])
    allow(Settings.application).to receive_messages(hostname: "example.com", schema: "https")
  end

  subject(:efz_antrag) { described_class.new(group, person) }

  describe "#form_data" do
    it "has the expected keys" do
      expect(efz_antrag.form_data.keys).to match_array [
        "mitglied_name",
        "mitglied_address",
        "mitglied_number",
        "mitglied_birthdate",
        "mitglied_city",
        "group_name",
        "group_address",
        "group_mail",
        "group_phone",
        "group_url",
        "efz_recipient_name",
        "efz_recipient_address",
        "date"
      ]
    end

    it "has the expected values" do
      data = efz_antrag.form_data
      expect(data["mitglied_name"]).to eq("Hans Muster")
      expect(data["mitglied_address"]).to be_a(String)
      expect(data["mitglied_number"]).to eq("12345")
      expect(data["mitglied_birthdate"]).to eq("01.01.1942")
      expect(data["mitglied_city"]).to eq("Berlin")
      expect(data["group_name"]).to eq("Adler Gruppe")
      expect(data["group_address"]).to be_a(String)
      expect(data["group_mail"]).to eq("gruppe@example.com")
      expect(data["group_phone"]).to eq("+49 30 123 45 67")
      expect(data["group_url"]).to include("https://example.com")
      expect(data["efz_recipient_name"]).to eq("Adler Gruppe")
      expect(data["efz_recipient_address"]).to be_a(String)
      expect(data["date"]).to eq(Date.current.strftime("%d.%m.%Y"))
    end

    it "can handle missing values" do
      group = Group::Stamm.new
      efz_verantwortliche_stelle = Group::Stamm.new(
        id: 42,
        einsichtnahme_efz_durch_gruppe: true
      )
      person = Person.new

      allow(group).to receive(:hierarchy).and_return([efz_verantwortliche_stelle, group])

      data = described_class.new(group, person).form_data
      expect(data["mitglied_name"]).to eq("")
      expect(data["mitglied_address"]).to be_a(String)
      expect(data["mitglied_number"]).to eq("")
      expect(data["mitglied_birthdate"]).to eq("")
      expect(data["mitglied_city"]).to eq("")
      expect(data["group_name"]).to eq("")
      expect(data["group_address"]).to be_a(String)
      expect(data["group_mail"]).to eq("")
      expect(data["group_phone"]).to eq("")
      expect(data["group_url"]).to include("https://example.com")
      expect(data["efz_recipient_name"]).to eq("")
      expect(data["efz_recipient_address"]).to be_a(String)
      expect(data["date"]).to eq(Date.current.strftime("%d.%m.%Y"))
    end
  end

  describe "#template_path" do
    let(:last_wagon) { double("Wagon", root: "/path/to/last") }
    let(:other_wagon) { double("Wagon", root: "/path/to/other") }
    let(:last_template_path) { File.join(last_wagon.root, Export::Pdf::EfzAntrag::TEMPLATE_PATH) }
    let(:other_template_path) { File.join(other_wagon.root, Export::Pdf::EfzAntrag::TEMPLATE_PATH) }

    before do
      allow(Wagons).to receive(:all).and_return([other_wagon, last_wagon])
    end

    it "returns the template path from the last wagon" do
      allow(File).to receive(:exist?).with(last_template_path).and_return(true)
      allow(File).to receive(:exist?).with(other_template_path).and_return(true)
      expect(efz_antrag.send(:template_path)).to eq(last_template_path)
    end

    it "raises when the template is missing" do
      allow(File).to receive(:exist?).with(last_template_path).and_return(false)
      expect { efz_antrag.send(:template_path) }.to raise_error(/Template not found/)
    end

    it "raises when only another wagon has the template" do
      allow(File).to receive(:exist?).with(last_template_path).and_return(false)
      allow(File).to receive(:exist?).with(other_template_path).and_return(true)
      expect { efz_antrag.send(:template_path) }.to raise_error(/Template not found/)
    end
  end

  describe "#generate" do
    let(:fixture_path) { HitobitoPfadiDe::Wagon.root.join("spec/fixtures/files/efz_antrag_template.pdf") }

    before do
      raise "Fixture not found. Run: ruby spec/fixtures/files/efz_antrag_template_generate.rb" unless
        File.exist?(fixture_path)
      allow(efz_antrag).to receive(:template_path).and_return(fixture_path.to_s)
      allow(Settings.application).to receive_messages(hostname: "example.com", schema: "https")
    end

    it "generates a valid PDF" do
      pdf_data = StringIO.new(efz_antrag.generate)
      expect(HexaPDF::Document.new(io: pdf_data).validate).to eq true
    end

    it "includes all expected values in the generated PDF" do
      pdf_data = StringIO.new(efz_antrag.generate)
      reader = PDF::Reader.new(pdf_data)
      text_content = ""
      reader.pages.each do |page|
        text_content += page.text
      end

      expected_values = {
        mitglied_name: "Hans Muster",
        mitglied_number: "12345",
        mitglied_birthdate: "01.01.1942",
        mitglied_city: "Berlin",
        mitglied_street: "Musterstrasse 1",
        mitglied_zip: "10115",
        group_name: "Adler Gruppe",
        group_mail: "gruppe@example.com",
        group_phone: "+49 30 123 45 67",
        group_city: "Berlin",
        group_street: "Gruppenstrasse 10",
        group_zip: "10117",
        efz_recipient_name: "Adler Gruppe",
        current_date: Date.current.strftime("%d.%m.%Y"),
        group_url: "https://example.com"
      }

      expected_values.each do |key, value|
        expect(text_content).to include(value), "PDF should contain '#{value}' (#{key})"
      end
    end

    it "does not fail when field is missing in the PDF template" do
      # this means EfzAntrag#form_data has a key with no corresponding field in the PDF template
      form_data_with_extra = efz_antrag.send(:form_data).merge("non_existent_field" => "some value")
      allow(efz_antrag).to receive(:form_data).and_return(form_data_with_extra)

      expect { efz_antrag.generate }.not_to raise_error
    end
  end
end
