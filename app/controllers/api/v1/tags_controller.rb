class Api::V1::TagsController < Api::V1::BaseController
  before_action :check_agent_access, except: [:get_kimai_detail]
  before_action :load_target,  except: [:company, :get_kimai_detail]
  before_action :assign_scope, except: [:company, :add_task_skills, :get_kimai_detail]

  attr_accessor :target, :scope

  VALID_SCOPES = ["skills".freeze, "flags".freeze, "generic_tags"].freeze

  #    api_v1_tags GET      /api/v1/tags(.:format)                                       api/v1/tags#index {:format=>:json}
  #                POST     /api/v1/tags(.:format)                                       api/v1/tags#create {:format=>:json}
  #     api_v1_tag PATCH    /api/v1/tags/:id(.:format)                                   api/v1/tags#update {:format=>:json}
  #                PUT      /api/v1/tags/:id(.:format)                                   api/v1/tags#update {:format=>:json}
  #                DELETE   /api/v1/tags/:id(.:format)                                   api/v1/tags#destroy {:format=>:json}
  # # Params examples:
  # { "scope": "skills", "task_id": 1, "add": ["linux"]}
  # { "scope": "skills", "user_id": 1, "add": ["linux", "osx"], "remove": []}
  def index
    render json: tag_list
  end

  def update
    [:add, :remove].each {|op| Array(params[op]).each {|tag| tag_list.send(op, tag) }}
    target.save ? respond_success : respond_failure
  end

=begin
  def get_kimai_detail
    @kimai_details = Kimai::KimaiDetail.all
    render :json => { data: @kimai_details, success: "Successful" }, status: :ok
  end
=end

  def destroy
    Array(params[:remove]).each {|tag| tag_list.send(:remove, tag)}
    target.save ? respond_success : respond_failure
  end

  def create
    Array(params[:add]).each {|tag| tag_list.send(:add, tag)}
    target.save ? respond_success : respond_failure
  end

  def company
    if stale?([current_user.company.updated_at, ActsAsTaggableOn::Tag.maximum(:id)])
      tags_hash = ActsAsTaggableOn::Tag.pluck(:name, :id).to_h
      priorities_hash = Priority.where(company_id: current_user.company.id).pluck(:tag_id, :priority_value).to_h
      render json: current_user.company.skill_list.map{|n| {category: :skills, label: n, priority: priorities_hash[tags_hash[n]]}}
    end
  end

  def add_task_skills
    company_skill_list = current_user.company.skill_list
    params[:add].split(',').map(&:strip).uniq.each do |tag|
      if company_skill_list.include?(tag)
        target.skill_list.add(tag)
      else
        target.generic_tag_list.add(tag)
      end
    end
    target.save
    target.reload
    render json: { tags: target.generic_tag_list, skills: target.skill_list }, status: :ok
  end

  private
  
  def respond_failure
    render json: { ok: false }, status: :unprocessable_entity
  end

  def respond_success
    target.reload
    render json: { ok: true, tags: tag_list }, status: :ok
  end

  def assign_scope
    if valid_scope?(params[:scope])
      @scope = params[:scope]
      true
    else
      render json: { ok: false}, status: :unprocessable_entity
      false
    end
  end

  def load_target
    puts params.inspect
    return true if @target = find_object
    render json: { ok: false}, status: :unprocessable_entity and return false
  end

  def tags
    target.send(scope)
  end

  def context
    return :task if params[:task_id].present?
    return :user if params[:user_id].present?
  end

  def target_id
    @target_id ||= params["#{context}_id".to_sym]
  end

  def tag_list
    target.send("#{scope.to_s.singularize}_list")
  end

  def find_object
    target_arel.try(:where, id: target_id).try(:first)
  end

  def target_arel
    target_class(context).try(:accessible_by, current_ability)
  end

  def target_class(context)
    case context
    when :user then User
    when :task then Task
    else nil
    end
  end

  def valid_scope?(scope_string)
    VALID_SCOPES.include?(scope_string)
  end

end

