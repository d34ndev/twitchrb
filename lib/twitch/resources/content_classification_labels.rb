module Twitch
  class ContentClassificationLabelsResource < Resource
    def list(locale: nil)
      response = get_request("content_classification_labels", params: { locale: locale }.compact)
      Collection.from_response(response, type: ContentClassificationLabel)
    end
  end
end
