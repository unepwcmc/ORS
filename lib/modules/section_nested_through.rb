module SectionNestedThrough #questionnaire_parts
  ###
  ###     Nested Set functions . Section is a nested set through "questionnaire_part".
  ###

  def self.append_features(base)
    super
    self.class_eval do

      def parent
        self.questionnaire_part.root? ? nil : self.questionnaire_part.parent.part
      end

      def ancestors
        #self.questionnaire_part.ancestors.map(&:part).delete_if{|a| !a.is_a?(self.class)}
        ids = self.questionnaire_part.ancestors.find(:all, :conditions => {:part_type => "#{self.class}"}, :select => 'part_id')
        self.class.find(ids.map(&:part_id), :joins => :questionnaire_part, :order => "questionnaire_parts.lft ASC")
      end

      def self_and_ancestors
        #self.questionnaire_part.self_and_ancestors.map(&:part).delete_if{|a| !a.is_a?(self.class)}
        ids = self.questionnaire_part.self_and_ancestors.find(:all, :conditions => {:part_type => "#{self.class}"}, :select => 'part_id')
        self.class.find(ids.map(&:part_id), :joins => :questionnaire_part, :order => "questionnaire_parts.lft ASC")
      end

      def is_ancestor_of? section
        self.questionnaire_part.is_ancestor_of? section.questionnaire_part
      end

      def is_or_is_ancestor_of? section
        self.questionnaire_part.is_or_is_ancestor_of? section.questionnaire_part
      end

      def descendants
        #self.questionnaire_part.descendants.map(&:part).delete_if{|a| !a.is_a?(self.class)}
        ids = self.questionnaire_part.descendants.find(:all, :conditions => {:part_type => "#{self.class}"}, :select => 'part_id')
        self.class.find(ids.map(&:part_id), :joins => :questionnaire_part, :order => "questionnaire_parts.lft ASC")
      end

      def self_and_descendants
        #self.questionnaire_part.self_and_descendants.map(&:part).delete_if{|a| !a.is_a?(self.class)}
        ids = self.questionnaire_part.self_and_descendants.find(:all, :conditions => {:part_type => "#{self.class}"}, :select => 'part_id')
        self.class.find(ids.map(&:part_id), :joins => :questionnaire_part, :order => "questionnaire_parts.lft ASC")
      end

      def is_descendant_of? section
        self.questionnaire_part.is_descendant_of? section.questionnaire_part
      end

      def is_or_is_descendant_of? section
        self.questionnaire_part.is_or_is_descendant_of? section.questionnaire_part
      end

      def siblings
        #self.questionnaire_part.siblings.map(&:part).delete_if{|a| !a.is_a?(self.class)}
        ids = self.questionnaire_part.siblings.find(:all, :conditions => {:part_type => "#{self.class}"}, :select => 'part_id')
        self.class.find(ids.map(&:part_id), :joins => :questionnaire_part, :order => "questionnaire_parts.lft ASC")
      end

      def self_and_siblings
        #self.questionnaire_part.self_and_siblings.map(&:part).delete_if{|a| !a.is_a?(self.class)}
        ids = self.questionnaire_part.self_and_siblings.find(:all, :conditions => {:part_type => "#{self.class}"}, :select => 'part_id')
        self.class.find(ids.map(&:part_id), :joins => :questionnaire_part, :order => "questionnaire_parts.lft ASC")
      end

      def children
        #self.questionnaire_part.children.map(&:part).delete_if{|a| !a.is_a?(self.class)}
        ids = self.questionnaire_part.children.find(:all, :conditions => {:part_type => "#{self.class}"}, :select => 'part_id')
        self.class.find(ids.map(&:part_id), :joins => :questionnaire_part, :order => "questionnaire_parts.lft ASC")
      end

      def root
        self.questionnaire_part.root.part
      end

      def root?
        self.questionnaire_part.root?
      end

      def leaf?
        self.questionnaire_part.leaf?
      end

      def level
        self.questionnaire_part.level
      end

      def lft
        self.questionnaire_part.lft
      end

    end
  end
end
