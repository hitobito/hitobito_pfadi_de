# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PfadiDe::RolesHelper do
  let(:group) { groups(:adler) }
  let(:person) { people(:bottom_leader) }
  let(:expected_role_class) { Group::Stamm::Materialwartung }

  before do
    allow(helper).to receive(:action_name).and_return("new")
    allow(helper).to receive(:can?).and_return(true)
  end

  it "returns array of objects with label and sti_name attributes" do
    options = helper.roles_type_options(group, Role.new(person:, group:))
    expect(options).to be_an(Array)
    expect(options.first).to respond_to(:label)
    expect(options.first).to respond_to(:sti_name)
    expect(options.map(&:sti_name)).to include(expected_role_class.sti_name)
  end

  it "does not include role types for which the user cannot create roles" do
    allow(helper).to receive(:can?)
      .with(:create, have_attributes(class: expected_role_class)).and_return(false)
    options = helper.roles_type_options(group, Role.new(person:, group:))
    sti_names = options.map(&:sti_name)
    expect(sti_names).not_to include(expected_role_class.sti_name)
  end
end
