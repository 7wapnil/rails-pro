module Account
  CustomerDataInput = GraphQL::InputObjectType.define do
    name 'CustomerDataInput'

    argument :trafficTypeLast, types.String
    argument :utmSourceLast, types.String
    argument :utmMediumLast, types.String
    argument :utmCampaignLast, types.String
    argument :utmContentLast, types.String
    argument :utmTermLast, types.String
    argument :visitcountLast, types.String
    argument :ipLast, types.String
    argument :browserLast, types.String
    argument :deviceTypeLast, types.String
    argument :devicePlatformLast, types.String
    argument :registrationUrlLast, types.String
    argument :timestampVisitLast, types.String
    argument :entrancePageLast, types.String
    argument :referrerLast, types.String
    argument :currentBtag, types.String
    argument :trafficTypeFirst, types.String
    argument :utmSourceFirst, types.String
    argument :utmMediumFirst, types.String
    argument :utmCampaignFirst, types.String
    argument :utmTermFirst, types.String
    argument :timestampVisitFirst, types.String
    argument :entrancePageFirst, types.String
    argument :referrerFirst, types.String
    argument :gaClientID, types.String
  end
end
