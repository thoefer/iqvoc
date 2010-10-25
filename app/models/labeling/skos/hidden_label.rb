class Labeling::SKOS::HiddenLabel < Labeling::SKOS::Base
  
  def build_rdf(document, subject)
    subject.Skos.hidden_label(target.to_s, :lang => target.language)
  end

  def self.view_section(obj)
    "hidden"
  end

end