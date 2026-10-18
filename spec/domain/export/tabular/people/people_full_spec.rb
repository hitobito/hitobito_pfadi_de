# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Export::Tabular::People::PeopleFull do
  let(:person) { people(:bottom_leader) }
  let(:list) { [person] }
  let(:people_list) { Export::Tabular::People::PeopleFull.new(list) }

  subject { people_list }

  it "includes bank account columns" do
    expect(subject.attributes).to include(:bank_account_owner, :iban, :bic, :bank_name)
  end

  it "includes latest_efz_issued_on" do
    expect(subject.attributes).to include(:latest_efz_issued_on)
  end

  it "includes leading_layer" do
    expect(subject.attributes).to include(:leading_layer)
  end

  context "standard attributes" do
    context "#attribute_labels" do
      subject { people_list.attribute_labels }

      its([:bank_account_owner]) { should eq "Kontoinhaber*in" }
      its([:iban]) { should eq "IBAN" }
      its([:bic]) { should eq "BIC" }
      its([:bank_name]) { should eq "Kreditinstitut" }
      its([:latest_efz_issued_on]) { should eq "eFZ Ausstellungsdatum" }
      its([:leading_layer]) { should eq "Hauptgruppierung" }
    end

    context "attribute values" do
      let!(:role) { roles(:bottom_leader) }

      subject { people_list.data_rows.first }

      before do
        person.update(
          bank_account_owner: "John Doe",
          iban: "CH66 0076 2011 6238 5295 8",
          bic: "DEUTDEFFXXX",
          bank_name: "Deutsche Bank",
          latest_efz_issued_on: "2026-05-20"
        )
      end

      it "contains attrs" do
        cols = people_list.attribute_labels.keys
        expect(subject[cols.index(:bank_account_owner)]).to eq "John Doe"
        expect(subject[cols.index(:iban)]).to eq "CH66 0076 2011 6238 5295 8"
        expect(subject[cols.index(:bic)]).to eq "DEUTDEFFXXX"
        expect(subject[cols.index(:bank_name)]).to eq "Deutsche Bank"
        expect(subject[cols.index(:latest_efz_issued_on)]).to eq "20.05.2026"
        expect(subject[cols.index(:leading_layer)]).to eq "Adler"
      end
    end
  end
end
