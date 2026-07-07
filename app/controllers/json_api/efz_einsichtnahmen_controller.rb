# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class JsonApi::EfzEinsichtnahmenController < JsonApiController
  def index
    authorize!(:index, EfzEinsichtnahme)
    super
  end

  def create
    authorize!(:create, EfzEinsichtnahme)
    super
  end

  def show
    authorize!(:show, entry)
    super
  end

  def destroy
    authorize!(:destroy, entry)
    super
  end

  private

  def entry
    @entry ||= EfzEinsichtnahme.find(params[:id])
  end
end
