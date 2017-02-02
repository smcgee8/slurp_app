require 'bundler/setup'
Bundler.require(:default)
require './config/environments'
require './teams/team'

#Always pass STDOUT to console
$stdout.sync = true

## JOBS ########################################################################

#Resque job for processing new files
module Process
  @queue = :files

  def self.perform(data)

    #Acquire info to interface with Dropbox & Slack APIs
    team = Team.find_by(team_id: data["team_id"])
    bot_access_token = team.bot_access_token
    dropbox_auth_token = team.dropbox_auth_token
    file_id = data["event"]["table"]["file_id"]

    #Get more information about file from Slack
    file_desc = post('https://slack.com/api/files.info',
                    {token: bot_access_token, file: file_id})
                    .file
    file_contents = RestClient.get(file_desc.url_private,
                                  {"Authorization" => "Bearer #{bot_access_token}"})
                                  .body
    channel_name = post('https://slack.com/api/channels.info',
                       {token: bot_access_token, channel: file_desc.channels[0]})
                       .channel.name

    #Connect to Dropbox API and upload file
    client = DropboxApi::Client.new(dropbox_auth_token)
    path = "/#{channel_name}/#{file_desc.timestamp}_#{file_desc.name}"
    client.upload(path, file_contents, {mode: :overwrite})

    #Announce to console that the job has been processed
    puts "Job for file at timestamp \"#{file_desc.timestamp}\" processed"

  end

end

## ROUTES ######################################################################

get '/' do
  #Display "Add to Slack" link
  erb :index
end

#Event callback from Slack
post '/events' do
  #Parse event callback from Slack
  request.body.rewind
  data = JSON.parse(request.body.read, object_class: OpenStruct)

  #Stop processing if message not verified to be from Slack
  halt 500 if data.token != ENV['SLACK_VERIFICATION_TOKEN']

  #Decide what to do based on type of callback
  case data.type

  #Verification response for registering a new Slack Event API endpoint
  when "url_verification"
    content_type :json
    return {challenge: data["challenge"]}.to_json

  #Callback for incidence of a specified Event
  when "event_callback"
    #If it's a file sharing event, enqueue a job to process the file
    if data.event.type == "file_shared"
      Resque.enqueue(Process, data.marshal_dump)
    end
  end

  #Respond to Slack API that we received the callback (within 3 seconds)
  return 200
end

#Slack authorization for new teams
get '/oauth' do
  #Has to have a code to be a valid callback
  if params['code']

    #Authenticate Slack connection and store new team info in our database
    options = {
      client_id: ENV['SLACK_CLIENT_ID'],
      client_secret: ENV['SLACK_CLIENT_SECRET'],
      code: params['code']
    }
    team = save_team(post('https://slack.com/api/oauth.access', options))

    #Create state variable to track team through remainder of setup process
    state = SecureRandom.hex(32)
    team.update(state: state)

    #Create authenticator that will initiate authorization of Dropbox
    authenticator = DropboxApi::Authenticator.new(ENV['DROPBOX_CLIENT_ID'],
                                                  ENV['DROPBOX_CLIENT_SECRET'])

    #Create URL that team will use to access Dropbox connection approval page
    url = authenticator.authorize_url(redirect_uri: ENV['DROPBOX_REDIRECT_URI'],
                                      state: state)

    #Send URL to the team via Slurp bot on Slack
    send_message("Please click the link to complete account setup: #{url}",
                 team.bot_access_token,
                 team.user_id)
  end
end

#Complete Dropbox authorization for new teams
get '/oauth2' do
  #Has to have a code to be a valid callback
  if params['code']

    #Look up team info using the state identifier previously established
    team = Team.find_by(state: params['state'])

    #Recreate authenticator that will complete Dropbox authorization
    authenticator = DropboxApi::Authenticator.new(ENV['DROPBOX_CLIENT_ID'],
                                                  ENV['DROPBOX_CLIENT_SECRET'])

    #Receive authorization token and store in team database entry
    auth_bearer = authenticator.get_token(params['code'],
                                          redirect_uri: ENV['DROPBOX_REDIRECT_URI'])
    team.update(dropbox_auth_token: auth_bearer.token)

    #Dispaly success page to indicate that account creation is complete
    erb :success
  end
end

## FUNCTIONS ###################################################################

#Save new team to the database
def save_team(input)
  team = Team.new do |t|
    t.access_token = input.access_token
    t.scope = input.scope
    t.user_id = input.user_id
    t.team_name = input.team_name
    t.team_id = input.team_id
    t.bot_user_id = input.bot.bot_user_id
    t.bot_access_token = input.bot.bot_access_token
  end
  team.save
  return team
end

#Send a message from the token user (usually Slurp bot) to the primary team user
def send_message(mes,token,user_id)

  #Open a direct message
  options = {
    token: token,
    user: user_id
  }
  channel_id = post('https://slack.com/api/im.open', options).channel.id

  #Send the message
  options = {
    token: token,
    channel: channel_id,
    text: mes
  }
  post('https://slack.com/api/chat.postMessage', options)

end

#Post to an API endpoint and store response in a structure
def post(endpoint, options)
  res = RestClient.post endpoint,
                        options,
                        content_type: :json

  return JSON.parse(res.body, object_class: OpenStruct)
end
