module ResourceController
  
  # == ResourceController::Base
  # 
  # Inherit from this class to create your RESTful controller.  See the README for usage.
  # 
  class Base < ApplicationController
    include ResourceController::Helpers
    include ResourceController::Actions
    extend  ResourceController::Accessors
    unloadable
    
    # Use this method in your controller to specify which actions you'd like it to respond to.
    #
    #   class PostsController < ResourceController::Base
    #     actions :all, :except => :create
    #   end
    def self.actions(*opts)
      config = {}
      config.merge!(opts.pop) if opts.last.is_a?(Hash)

      actions_to_remove = []
      actions_to_remove += (ResourceController::ACTIONS - [:new_action] + [:new]) - opts unless opts.first == :all                
      actions_to_remove += [*config[:except]] if config[:except]
      actions_to_remove.uniq!
      
      actions_to_remove.each { |action| undef_method(action)}
    end
    
    helper_method :object_url, :edit_object_url, :new_object_url, :collection_url, :object, :collection, 
                    :parent, :parent_type, :parent_object, :model_name, :model
    
    def self.inherited(subclass)
      super
      
      subclass.class_eval do        
        class_reader_writer :belongs_to
        
        cattr_accessor :action_options
        self.action_options ||= {}
        
        (ResourceController::ACTIONS - ResourceController::FAILABLE_ACTIONS).each do |action|
          class_scoping_reader action, ResourceController::ActionOptions.new
          self.action_options[action] = send action
        end
        
        ResourceController::FAILABLE_ACTIONS.each do |action|
          class_scoping_reader action, ResourceController::FailableActionOptions.new
          self.action_options[action] = send action
        end

        index.wants.html
        edit.wants.html
        new_action.wants.html
        
        show do
          wants.html
          
          failure.wants.html { render :text => "Member object not found." }
        end

        create do
          flash "Successfully created!"
          wants.html { redirect_to object_url }
  
          failure.wants.html { render :action => "new" }
        end

        update do
          flash "Successfully updated!"
          wants.html { redirect_to object_url }
  
          failure.wants.html { render :action => "edit" }
        end

        destroy do
          flash "Successfully removed!"
          wants.html { redirect_to collection_url }
        end
        
      end
                
    end
  end
end