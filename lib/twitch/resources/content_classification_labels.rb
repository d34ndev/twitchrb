module Twitch
  class ContentClassificationLabelsResource < Resource
    def list(locale: nil)
      response = get_request("content_classification_labels", params: { locale: locale }.compact)
      collection(response, type: ContentClassificationLabel)
    end
  end
end
