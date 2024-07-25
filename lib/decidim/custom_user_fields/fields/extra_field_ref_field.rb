module Decidim
    module CustomUserFields
      module Fields
        class ExtraFieldRefField < GenericField
          attr_accessor :reference

          def configure_form(form)
              match = Decidim::CustomUserFields.custom_fields.find {|field| field.name == name}
              self.reference = Marshal.load(Marshal.dump(match))
              reference.options = reference.options.merge(options)
              options = reference.options
              
              reference.configure_form(form)
          end
          
          def map_model(form, data)
            raise Error, "Can't use Extra Field Ref for registration"
          end

          def form_tag(form)
            user = current_user(form)
            extended_data = user.extended_data.with_indifferent_access
            have_content = reference.map_model(form.object, extended_data)
            if have_content && options[:hide_if_value]
              content_tag(
                :div,
                form.hidden_field(name),
                class: class_name +  " #{class_modifer("hidden")}"
              )
            else
              old_context = reference.i18n_context
              reference.i18n_context = i18n_context
              field_tag = reference.form_tag(form)
              reference.i18n_context = old_context
              field_tag
            end
          end

          def i18n_context
            "decidim.custom_user_fields.extended_data"
          end

          private

          def current_user(form)
            form.object.user
          end
  
        end
      end
    end
  end
  