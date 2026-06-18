# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe People::EfzAntragsController do
  let(:group) { groups(:pfadfinder) }
  let(:person) { people(:member) }

  before { sign_in(person) }

  describe "POST#create" do
    it "authorizes show permission" do
      other = Fabricate(Group::StammGruppePfadfinder::Mitglied.sti_name, group:).person
      expect do
        get :show, params: {group_id: group.id, person_id: other.id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "generates inline pdf" do
      get :show, params: {group_id: group.id, person_id: person.id}
      expect(response).to be_successful
      expect(response.content_type).to eq "application/pdf"
      expect(response.headers["content-disposition"]).to eq "inline"
    end
  end
end
