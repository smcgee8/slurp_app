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
    channel_name = post('https://slack.com/api/channels.info',
                       {token: bot_access_token, channel: file_desc.channels[0]})
                       .channel.name

    #Determine title and path for new Dropbox file
    title = file_desc.title
                     .encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ''})
                     .gsub(/.#{file_desc.filetype}/i, "")
                     .gsub(" ", "_")
                     .delete("/")
    path = "/#{channel_name}/#{file_desc.timestamp}_#{title}.#{file_desc.filetype}"

    #Connect to Dropbox API
    client = DropboxApi::Client.new(dropbox_auth_token)

    #Files will be sent in 4 megabyte chunks
    chunk_size = 4 * 1024 * 1024
    #Open IO with file's Slack url
    open(file_desc.url_private, {"Authorization" => "Bearer #{bot_access_token}"}) do |f|
      #If file is less than chunk-size, we can take it all at once
      if file_desc.size < chunk_size
        client.upload(path, f.read, {mode: :overwrite, mute: true})
      #If file is larger than chunk-size, we will take it in increments using Dropbox upload sessions interface
      else
        start_resp = client.upload_session_start(f.read(chunk_size))
        cursor = {session_id: start_resp.session_id, offset: f.tell()}
        commit = {path: path, mode: :overwrite, mute: true}
        #Continue to read and upload file until we reach the end
        while f.eof == false
            client.upload_session_append_v2(cursor, f.read(chunk_size))
            cursor[:offset] = f.tell()
        end
        #Close upload sessions
        client.upload_session_finish(cursor, commit)
      end
    end

    #Announce to console that the job has been processed
    puts "Job for file at timestamp \"#{file_desc.timestamp}\" processed"
  end
end

#Resque job for a request to update all files
module Update
  @queue = :requests

  def self.perform(data)
    #Acquire info to interface with Dropbox & Slack APIs
    team = Team.find_by(team_id: data["team_id"])
    bot_access_token = team.bot_access_token
    user_access_token = team.access_token

    #Find channels in which slurp bot is a member
    channels = post('https://slack.com/api/channels.list',
               {token: bot_access_token})
               .channels.select{|channel| channel.is_member == true}

    #Interate through channels to find all shared files
    channels.each do |channel|

      #Receive first list of files for a particular channel and check pages
      file_list = post('https://slack.com/api/files.list',
                  {token: user_access_token, channel: channel.id})
      pages = file_list.paging.pages

      #Iterate through all the pages
      (1..pages).each do |n|

        #If past the 1st page, pull the next page
        if n > 1
          file_list = post('https://slack.com/api/files.list',
                      {token: user_access_token, channel: channel.id, page: n})
        end

        #Add each file in the list to the queue for Process jobs
        files = file_list.files
        files.each do |file|
          data["event"]["table"]["file_id"] = file.id
          Resque.enqueue(Process, data)
        end

        #Post info about this channel to console
        puts "#{files.count} files identified in channel \"#{channel.name}\" and enqueued for processing."
      end
    end
  end
end

## ROUTES ######################################################################

get '/' do
  #Display "Add to Slack" link
  erb :index
end

#Receive event from Slack
post '/events' do
  #Parse event
  request.body.rewind
  data = JSON.parse(request.body.read, object_class: OpenStruct)

  #Print request headers for retries to console
  puts "Retry Num: #{request.env["HTTP_X_SLACK_RETRY_NUM"] ||= 0} #{request.env["HTTP_X_SLACK_RETRY_REASON"]}"

  #Stop processing if message not verified to be from Slack
  halt 500 if data.token != ENV['SLACK_VERIFICATION_TOKEN']

  #Decide what to do based on type of event
  case data.type
  #Verification response for registering a new Slack Event API endpoint
  when "url_verification"
    content_type :json
    return {challenge: data["challenge"]}.to_json

  #Type for detected event
  when "event_callback"
    #If it's a file sharing event, enqueue a job to process the file
    if data.event.type == "file_shared"
      Resque.enqueue(Process, data.marshal_dump)

    #If it's a message that says "update all", enqueue an update request
    elsif data.event.type == "message"
      if data.event.text == "update all"
        Resque.enqueue(Update, data.marshal_dump)
      end
    end

    #Need to respond to Slack with 200 code within 3 seconds to prevent retry
    status 200
  end
end

#Slack authorization for new teams
get '/oauth' do
  #Has to have a code to be a valid request
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
    send_message("Hello! There's just one more step to complete setup — Please click this link to authorize your Dropbox account: #{url}",
                 team.bot_access_token,
                 team.user_id)

   #Dispaly success page to indicate that account creation is complete
   erb :success
  end
end

#Complete Dropbox authorization for new teams
get '/oauth2' do
  #Has to have a code to be a valid request
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

    #Confirm setup completion via Slurp bot on Slack
    send_message("Setup is all done! Invite me (@slurp) to channels you want to keep synced. To resync all files, just send me a message that says 'update all'.",
                 team.bot_access_token,
                 team.user_id)

    #Dispaly success page to indicate that account creation is complete
    erb :success
  end
end

## FUNCTIONS ###################################################################

#Save new team to the database
def save_team(input)
  #Only create new team entry if team_id is new, otherwise only update scope
  t = Team.find_by(team_id: input.team_id)
  if t == nil
    t = Team.new
    t.access_token = input.access_token
    t.scope = input.scope
    t.user_id = input.user_id
    t.team_name = input.team_name
    t.team_id = input.team_id
    t.bot_user_id = input.bot.bot_user_id
    t.bot_access_token = input.bot.bot_access_token
  else
    t.scope = input.scope
  end

  #Save updates and return
  t.save
  return t
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
  #Send request
  res = RestClient.post endpoint,
                        options,
                        content_type: :json

  #Process and return response
  return JSON.parse(res.body, object_class: OpenStruct)
end
