# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class JsonApi::FeeKindsController < JsonApiController
  def index
    authorize!(*index_authorization_args)
    super
  end

  def show
    authorize!(:show, entry)
    super
  end

  private

  def entry
    @entry ||= FeeKind.find(params[:id])
  end

  def index_authorization_args
    case current_ability
    when TokenAbility then [:index, FeeKind]
    else [:finance, Group]
    end
  end
end
