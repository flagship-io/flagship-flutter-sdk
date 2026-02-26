/// Unforce a campaign by clearing its QA modifications
void unforceCampaign(String campaignId) {
  print('🧹 MessageService: Unforceing campaign $campaignId');
  
  // Broadcast message with action 'unforce'
  _campaignActionController.add(CampaignActionMessage(
    campaignId: campaignId,
    action: 'unforce',
  ));
  
  print('✅ Unforce campaign message sent');
}