# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe GroupDecorator, :draper_with_helpers do
  let(:group) { groups(:adler_mitglieder) }

  subject(:decorator) { group.decorate }

  it "supports_self_registration? always returns false" do
    # In core, self registration is supported if allowed_roles_for_self_registration is present.
    # In pfadi_de, self registration is always disabled.
    expect(decorator.allowed_roles_for_self_registration).to be_present
    expect(decorator.supports_self_registration?).to be false
  end
end
