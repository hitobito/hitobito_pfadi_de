# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Person::HistoryController do
  render_views

  let(:body) { Capybara::Node::Simple.new(response.body) }
  let(:person) { people(:member) }
  let(:group) { groups(:pfadfinder) }
  let(:user) { people(:admin) }

  before { sign_in(user) }

  def get_index
    get :index, params: {group_id: group.id, id: person.id}
  end

  it "renders and counts membership application section" do
    person.update!(membership_application_reasons: "weil ich dabei sein möchte")
    get_index

    expect(body).to have_css "#membership_application", text: "weil ich dabei sein möchte"
    expect(controller.send(:history_section_sizes).last).to eq 1
  end

  it "renders and counts efz einsichtnahmen section" do
    Fabricate(Group::Stamm::ErfassungFuehrungszeugnis.sti_name, person: user, group: groups(:adler))
    2.times { Fabricate(:efz_einsichtnahme, person: person) }
    get_index

    expect(body).to have_css "#efz_einsichtnahmen tbody tr", count: 2
    expect(controller.send(:history_section_sizes).last).to eq 2
  end
end
