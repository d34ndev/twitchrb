module Twitch
  class CustomPowerUpsResource < Resource
    # Required scope: bits:read
    # broadcaster_id must match the currently authenticated user
    def list(broadcaster_id:, ids: nil)
      params = { broadcaster_id: broadcaster_id }
      params[:id] = ids if ids

      response = get_request("bits/custom_power_ups", params: params)
      collection(response, type: CustomPowerUp)
    end
  end
end
