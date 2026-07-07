# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe JsonApi::EfzEinsichtnahmeAbility do
  let(:member) { people(:member) }
  let(:efz) { EfzEinsichtnahme.new(person: member) }

  subject { JsonApi::EfzEinsichtnahmeAbility.new(user) }

  context "when having full read permission on person" do
    let(:user) { people(:admin) }

    it { is_expected.to be_able_to(:read, efz) }
  end

  context "when missing full read permission on person" do
    let(:user) { Fabricate(:person) }

    it { is_expected.not_to be_able_to(:read, efz) }
  end
end
