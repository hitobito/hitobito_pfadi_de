# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

# Registered as TableDisplays::ShowDetailsColumn for :latest_efz_issued_on in
# HitobitoPfadiDe::Wagon, not a dedicated column class.
describe TableDisplays::ShowDetailsColumn, type: :helper do
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
    person.update!(latest_efz_issued_on: "2026-05-20", gender: "m")
  end

  it_behaves_like "table display", {
    column: :latest_efz_issued_on,
    header: "eFZ Ausstellungsdatum",
    value: "20.05.2026",
    export_value: "2026-05-20",
    permission: :show_details
  }
end
