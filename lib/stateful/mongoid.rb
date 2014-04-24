module Stateful
  module MongoidIntegration
    extend ActiveSupport::Concern

    module ClassMethods
      protected

      def define_state_attribute(options)
        field options[:name].to_sym, type: Symbol, default: options[:default]
        validates_inclusion_of options[:name].to_sym,
                               in: __send__("#{options[:name]}_infos").keys,
                               message:  options.has_key?(:message) ? options[:message] : "has invalid value",
                               allow_nil: !!options[:allow_nil]

        # configure scopes to query the attribute value
        __send__("#{options[:name]}_infos").values.each do |info|
          states = info.collect_child_states
          scope_name = "#{options[:prefix]}#{info.name}"
          if states.length == 1
            scope scope_name, where(options[:name] => states.first)
          else
            scope scope_name, where(options[:name].to_sym.in => states)
          end
        end

        # provide a previous_state helper since mongoid provides the state_change method for us
        define_method "previous_#{options[:name]}" do
          changes = __send__("#{options[:name]}_change")
          changes.first if changes and changes.any?
        end

        define_method "previous_#{options[:name]}_info" do
          state = __send__("previous_#{options[:name]}")
          self.class.__send__("#{options[:name]}_infos")[state] if state
        end

      end
    end
  end
end