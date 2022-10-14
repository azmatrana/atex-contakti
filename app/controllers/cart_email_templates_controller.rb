class CartEmailTemplatesController < ApplicationController

    before_action :set_company, only: [:create_update_order_placed_template, :create_update_payment_link_template, :create_update_terms_and_conditions_template, :get_order_placed_template, :get_order_payment_link_template, :get_order_terms_and_conditions_template]

    def create_update_order_placed_template
        @template = @company.cart_email_templates.find_or_initialize_by(template_for: "order_placed")
        @template.attributes = template_params

        if @template.save
            render json: { data: @template.as_json , success: t('tags.saved_successfully')}
        else
            render :json => { :errors => @template.errors.full_messages }
        end
    end

    def create_update_payment_link_template
        @template = @company.cart_email_templates.find_or_initialize_by(template_for: "order_payment_link")
        @template.attributes = template_params

        if @template.save
            render json: { data: @template.as_json , success: t('tags.saved_successfully')}
        else
            render :json => { :errors => @template.errors.full_messages }
        end
    end

    def create_update_terms_and_conditions_template
        @template = @company.cart_email_templates.find_or_initialize_by(template_for: "terms_and_conditions")
        @template.attributes = template_params

        if @template.save
            render json: { data: @template.as_json , success: t('tags.saved_successfully')}
        else
            render :json => { :errors => @template.errors.full_messages }
        end
    end

    def get_order_placed_template
        @template = @company.cart_email_templates.find_by(template_for: "order_placed")
        render json: @template.as_json
    end

    def get_order_payment_link_template
        @template = @company.cart_email_templates.find_by(template_for: "order_payment_link")
        render json: @template.as_json
    end

    def get_order_terms_and_conditions_template
        @template = @company.cart_email_templates.find_by(template_for: "terms_and_conditions")
        render json: @template.as_json
    end

    private

    def set_company
        @company = current_user.company
    end

    def template_params
        params.require(:cart_email_template).permit(
            :subject,
            :body
        )
      end
end
