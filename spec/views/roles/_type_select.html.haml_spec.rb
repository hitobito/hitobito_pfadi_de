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
    OpenStruct.new(label: "Test Role", sti_name: "Role::Test")
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

  it "renders a collection_select with role type options" do
    expect(dom).to have_select("role[type]", with_options: [test_option.label])
  end

  it "uses sti_name as value and label as text" do
    expect(dom).to have_css("select option[value='#{test_option.sti_name}']", text: test_option.label)
  end
end
