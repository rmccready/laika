# This module extends an ActiveRecord::Base class with class methods for declaring
# assocations that involve c32 modules
#
# It's used in Patient (and potentially elsewhere) to declare dependent c32
# submodules.
#
#  has_many_c32 :medications
#
# is mostly equivalent to:
#
#  has_many :medications, :dependent => :destroy
#
# However, the medications association has a method to_c32 that
# will aggregate the results of calling to_c32 on each record. Additionally,
# if the Medication class has a class method c32_component it will be used
# to render surrounding boilerplate using a passed XML builder object.
#
# NOTE that the c32_component method (if present) MUST yield the passed xml
# builder to render each record's c32.
#
# has_one_c32 doesn't include any functionality related to C32 generation,
# it's just there to document which associations are c32-related. It also
# causes dependents to be destroyed on deletion.
#
module HasC32ComponentExtension

  # options:
  # * :component_module => name of the C32 component module this association
  #   describes (defaults to the association name)
  def has_many_c32(rel, args = {})
    _extend_for_c32(:has_many, rel, args)
  end

  # options:
  # * :component_module => name of the C32 component module this association
  #   describes (defaults to the association name)
  def has_one_c32(rel, args = {})
    _extend_for_c32(:has_one, rel, args)
  end

  private

  def _extend_for_c32(macro, rel, args)
    component_module = args.delete(:component_module)
    send(macro, rel, args.merge(:extend => C32Component, :dependent => :destroy))
    reflection = reflect_on_association(rel)
    reflection.extend(C32Reflection)
    reflection.c32_component_module_name = component_module
  end

  # Methods specific to an association of C32 components.  These module
  # adds functionality relevant to the collection of C32 components as
  # a whole, rather than to an individual C32 object.
  module C32Component

    # Returns the name of the C32 component module described by the objects in
    # this association.  This may be set with the :component_module option
    # in the original has_many/one_c32 macro; otherwise defaults to the name of
    # the association.
    #
    # Returns a symbol.
    def component_module
      proxy_reflection.c32_component_module_name
    end

    # True if this component has a single entry.  False if it has multiple entries.
    def singular?
      proxy_reflection.macro == :has_one
    end

    def to_c32(xml)
      if singular?
        proxy_target.to_c32(xml)
      elsif proxy_reflection.klass.respond_to? :c32_component
        proxy_reflection.klass.c32_component(self, xml) { map {|r| r.to_c32(xml)} }
      else
        map {|r| r.to_c32(xml)}
      end
    end
  end

  # Extends the reflection proxy with state specific to a C32 association.  The
  # activerecord association class macros such as has_many, create Reflections
  # that hold the information needed to generate a working association in a
  # given activerecord instance.  Although we can customize the behavior of an
  # association by extending it with a module, if we want to associate
  # additional state with an association, such as it's C32 component module
  # name, we need to extend the reflection itself.  This can then be accessed
  # through the instantiated association's proxy_reflection()
  module C32Reflection

    def c32_component_module_name
      (@c32_component_module_name || self.name).to_sym
    end
    
    def c32_component_module_name=(c32_component_module_name)
      s = c32_component_module_name.to_s
      return if s.blank?
      @c32_component_module_name = s.gsub(/ /,'_').underscore.to_sym
    end

  end
end

ActiveRecord::Base.extend(HasC32ComponentExtension)
