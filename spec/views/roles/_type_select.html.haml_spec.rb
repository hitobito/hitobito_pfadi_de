# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe "roles/_type_select.html.haml" do
  let(:group) { groups(:adler) }
  let(:person) { people(:bottom_leader) }
  let(:role) { Role.new(person:, group:) }
  let(:test_option) do
    ["Test Role", "Role::Test"]
  end
  let(:dom) {
    render partial: "roles/type_select", locals: {entry: role}
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    assign(:group, group)
    allow(view).to receive(:roles_type_options).and_return([test_option])
    allow(view).to receive(:roles_type_select_options).and_return({})
    allow(view).to receive(:details_group_roles_path).and_return("/groups/1/roles/details")
  end

  it "renders a select with role type options" do
    expect(dom).to have_css("select option[value='#{test_option.last}']", text: test_option.first)
  end
end
