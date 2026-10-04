# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe TableDisplays::People::SepaMandateColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:table) { StandardTableBuilder.new([person], self) }
  let(:person) { people(:member).decorate }
  let(:ability) { Ability.new(people(:admin)) }
  let(:group) { groups(:adler) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(group)
  end

  context "without active mandate" do
    it_behaves_like "table display", {
      column: :payment_method,
      header: "Zahlungsart",
      value: "Überweisung",
      permission: :show_details
    }
  end

  context "with active mandate" do
    let!(:mandate) { Fabricate(:sepa_mandate, person: people(:member), group: groups(:adler)) }

    it_behaves_like "table display", {
      column: :payment_method,
      header: "Zahlungsart",
      value: "Lastschrift",
      permission: :show_details
    }

    it "renders the references of the active mandates" do
      column = described_class.new(ability, table:, model_class: Person)

      expect(column.label(:sepa_mandate_references)).to eq "Mandatsreferenz"
      expect(column.value_for(people(:member), :sepa_mandate_references)).to eq mandate.reference
    end
  end
end
