require 'citeproc'

module AsciidoctorCsl
  module CiteprocPatches
    # Leaks suppressed variables into later renders.
    module SeparateSuppression
      def initialize_copy(other)
        super
        @suppressed = nil
      end
    end
  end
end

CiteProc::Item.prepend AsciidoctorCsl::CiteprocPatches::SeparateSuppression
