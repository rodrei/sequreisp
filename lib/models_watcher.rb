module ModelsWatcher

  def self.included(base)
    return if base.include? InstanceMethods

    base.send(:include, InstanceMethods)
    base.send(:extend, ClassMethods)

    base.class_eval do
      @__watched_fields ||= []
      before_save :check_watched_fields
    end
  end

  module ClassMethods

    def watch_fields(*fields)
      @__watched_fields += fields
    end

    def watch_on_destroy
      after_destroy :update_changes_to_apply
    end

  end

  module InstanceMethods

    def check_watched_fields
      if @__skip_check_watched_fields_callback
        @__skip_check_watched_fields_callback = false
        return
      end

      fields = self.class.instance_eval do @__watched_fields end
      fields.each do |field|
        if self.send "#{field}_changed?"
          update_changes_to_apply
          break
        end
      end
    end

    def update_changes_to_apply
      if Configuration.first
        Configuration.first.update_attribute(:changes_to_apply, true)
      end
    end

    def save_without_applying_changes
      @__skip_check_watched_fields_callback = true
      save
    end
  end

end
