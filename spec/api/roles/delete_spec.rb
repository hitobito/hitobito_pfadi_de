# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe "roles#delete", type: :request do
  def jsonapi_headers
    super.merge("X-TOKEN" => service_tokens(:permitted_root_token).token)
  end

  let(:group) { groups(:adler_mitglieder) }
  let!(:role) do
    Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name, group:,
      start_on: Time.zone.today, created_at: 33.days.ago)
  end

  subject(:make_request) do
    jsonapi_delete "/api/roles/#{role.id}"
  end

  it "does not hard destroy membership role starting today created long ago" do
    expect {
      make_request
      expect(response.status).to eq(400), response.body
      expect(errors[0].message)
        .to eq "Eine Mitgliedschaft kann nur innerhalb von 32 Tagen nach dem Erfassen gelöscht werden."
    }.not_to change { Role.with_inactive.count }
  end

  it "hard destroys recently created membership role starting today" do
    role.update_columns(created_at: 32.days.ago)

    expect {
      make_request
      expect(response.status).to eq(200), response.body
    }.to change { Role.with_inactive.count }.by(-1)
  end
end
