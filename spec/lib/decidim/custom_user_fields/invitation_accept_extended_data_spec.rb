# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::InvitationAcceptExtendedData do
  let(:controller_class) do
    Class.new do
      prepend Decidim::CustomUserFields::InvitationAcceptExtendedData

      attr_accessor :params

      def resource_class
        Decidim::User
      end
    end
  end

  describe "#validate_custom_params" do
    it "rejects text values outside values_in before accepting the invitation" do
      with_customizations do
        organization = create(:organization)
        register_test_customization(:default) do |customization|
          customization.registration_fields do |set|
            set.add_field(:role, type: :text, values_in: %w(member admin), required: true)
          end
        end
        enable_customization_for(organization, :default)

        invited = Decidim::User.invite!(
          { email: "invited@example.org", name: "Invited", organization: },
          create(:user, :admin, organization:)
        )

        controller = controller_class.new
        controller.params = {
          user: {
            invitation_token: invited.raw_invitation_token,
            default_role: "guest"
          }
        }
        allow(controller).to receive(:invitation_organization).and_return(organization)

        errors = controller.send(:validate_custom_params, controller.send(:extract_custom_field_params))

        expect(errors.messages[:default_role]).to be_present
      end
    end
  end
end
