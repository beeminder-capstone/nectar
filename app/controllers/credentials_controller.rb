=begin
 * Created by PSU Beeminder Capstone Team on 3/12/2017.
 * Copyright (c) 2017 PSU Beeminder Capstone Team
 * This code is available under the "MIT License".
 * Please see the file LICENSE in this distribution for license terms.
=end
class CredentialsController < AuthenticatedController
  helper_method def credential
    @_credential ||=
      begin
        collection = current_user.credentials
        credential = collection.find_by(id: params[:id])
        credential ||= collection.find_or_initialize_by(
          provider_name: params_provider_name
        )
        CredentialDecorator.new(credential)
      end
  end

  helper_method def provider
    @_provider ||= ProviderDecorator.new(credential.provider)
  end

  before_action :require_provider

  def new
    if credential.persisted?
      redirect_to provider.root_path
    elsif provider.oauth?
      redirect_to "/auth/#{provider.name}"
    else
      render :edit
    end
  end

  def create
    update
  end

  def update
    if credential.update_attributes credential_params
      redirect_to "/credentials/#{provider.name}", notice: "Configured successfully!"
    else
      flash[:error] = credential.errors.full_messages.join(" ")
      redirect_to :back
    end
  end

  def destroy
    credential.destroy!
    redirect_to root_path, notice: "Credentials deleted successfully for #{provider.name}."
  end

  private

  def credential_params
    if provider.public? || provider.password_auth? || provider.verify_auth?
      params.require(:credential).permit(:uid, :password, :verification_code)
    else
      {}
    end
  end

  def params_provider_name
    params[:provider_name] || (params[:credential] || {})[:provider_name]
  end

  def require_provider
    render(status: 404) if provider.nil?
  end
end
