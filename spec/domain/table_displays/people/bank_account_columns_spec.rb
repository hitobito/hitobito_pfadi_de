# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

# Registered as TableDisplays::ShowFullColumn for PfadiDe::Contactable::BANK_ACCOUNT_ATTRS in
# HitobitoPfadiDe::Wagon, not a dedicated column class.
describe TableDisplays::ShowFullColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:table) { StandardTableBuilder.new([person], self) }
  let(:person) { people(:member).decorate }
  let(:ability) { Ability.new(person) }
  let(:group) { groups(:adler_mitglieder) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(group)
    allow_any_instance_of(ActionView::Base).to receive(:params).and_return(
      ActionController::Parameters.new(controller: "people", action: "index", group_id: group.id.to_s)
    )
    person.update!(bank_account_owner: "John Doe", gender: "m")
  end

  it_behaves_like "table display", {
    column: :bank_account_owner,
    header: "Kontoinhaber*in",
    value: "John Doe",
    permission: :show_full
  }

  describe "registration" do
    PfadiDe::Contactable::BANK_ACCOUNT_ATTRS.each do |attr|
      it "registers #{attr} as a ShowFullColumn" do
        expect(TableDisplay.table_display_columns.fetch("Person")[attr.to_s])
          .to eq TableDisplays::ShowFullColumn
      end
    end
  end
end
