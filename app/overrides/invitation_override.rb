# frozen_string_literal: true

Deface::Override.new(
  virtual_path: "decidim/devise/invitations/edit",
  name: "decidim_user_field_add_extra_user_fields_to_invitation_edit",
  insert_after: "erb[loud]:contains('f.text_field :nickname')",
  text: <<~ERB
    <!-- add email as hidden field -->
    <%= f.hidden_field :email %>
    <%= render partial: '/decidim/custom_user_fields/registration_form', locals: { f: f, resource: resource } %>
  ERB
)

Deface::Override.new(
  virtual_path: "decidim/devise/invitations/edit",
  name: "decidim_user_field_add_invitation_token_to_invitation_edit",
  replace: "erb[loud]:contains('f.hidden_field :invitation_token')",
  text: <<~ERB
    <%= f.hidden_field :invitation_token, value: f.object.context.invitation_token %>
  ERB
)

Deface::Override.new(
  virtual_path: "decidim/devise/invitations/edit",
  name: "decidim_user_field_replace_invitation_form",
  replace: "erb[loud]:contains('decidim_form_for')",
  text: <<~ERB
    <% form = @form || Decidim::RegistrationForm.from_model(resource).with_context(current_organization: current_organization, current_user: current_user, invitation_token: resource.invitation_token) %>
    <%= decidim_form_for form, namespace: "invitation", as: resource_name, url: invitation_path(resource_name, invite_redirect: params[:invite_redirect]), html: { method: :put, class: "register-form new_user" } do |f| %>
  ERB
)
