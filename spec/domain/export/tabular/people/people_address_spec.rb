# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Export::Tabular::People::PeopleAddress do
  let(:person) { people(:bottom_leader) }
  let(:list) { [person] }
  let(:people_list) { Export::Tabular::People::PeopleAddress.new(list) }

  subject { people_list }

  it "includes pfadfinder columns" do
    expect(subject.attributes).to include(:pronoun, :entry_date, :exit_date)
  end

  it "does not include bank account or payment method columns" do
    expect(subject.attributes).not_to include(:bank_account_owner, :iban, :bic, :bank_name,
      :payment_method)
  end

  context "standard attributes" do
    context "#attribute_labels" do
      subject { people_list.attribute_labels }

      its([:pronoun]) { should eq "Pronomen" }
      its([:entry_date]) { should eq "Eintrittsdatum" }
      its([:exit_date]) { should eq "Austrittsdatum" }
    end

    context "attribute values" do
      let!(:role) { roles(:bottom_leader) }

      subject { people_list.data_rows.first }

      before do
        person.update(pronoun: "er/ihn")
        Group::Mitglieder::OrdentlicheMitgliedschaft.create!(
          person: person,
          group: groups(:adler_mitglieder),
          start_on: "2025-08-01",
          end_on: "2025-08-13",
          fee_kind: fee_kinds(:baden_wuerttemberg_kind)
        )
      end

      it "contains attrs" do
        cols = people_list.attribute_labels.keys
        expect(subject[cols.index(:pronoun)]).to eq "er/ihn"
        expect(subject[cols.index(:entry_date)]).to eq "01.08.2025"
        expect(subject[cols.index(:exit_date)]).to eq "13.08.2025"
      end
    end
  end
end
