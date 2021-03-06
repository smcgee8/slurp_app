# ![slurp_app](public/img/LogoBig.png)

## Synopsis
Slurp syncs files posted on Slack to your Dropbox. Simply invite the Slurp bot to any Slack channel you wish to index — whenever someone posts a new file, a copy will magically appear on Dropbox.

## Usage
The project is currently deployed at https://sheltered-bastion-69963.herokuapp.com/ (it may take the page ~5-10 seconds to load if the app is currently idle). Anyone who wishes to install Slurp for their team may do so by clicking **Add to Slack** at that URL.

Once Slurp has been added to your Slack team, the Slurp bot will send you a direct message with a link to connect Slurp to your Dropbox account. After completing setup, the Slurp bot can be invited to any channel in Slack to begin indexing files posted to that channel.
```
/invite @slurp
```
Files will be stored on the connected Dropbox account in a folder automatically created by Slurp.
```
/Slurp App/[TEAM NAME]/[CHANNEL NAME]
```
You may wish to index files posted prior to the Slurp bot joining a channel. Sending **'update all'** to the Slurp bot as a direct message will index the full file history of all channels the bot is currently a member of.

## Deployment
Slurp can also be modified & independently deployed easily using Heroku.

1. Clone the slurp_app repository (or your own fork) to create a local copy.  
  ```
  $ git clone https://github.com/[USERNAME]/[REPOSITORY]
  ```

1. Create a new Heroku application with the necessary add-ons to support Slurp.  
  ```
  $ heroku create
  $ heroku addons:create heroku-postgresql:hobby-dev
  $ heroku addons:create heroku-redis:hobby-dev
  ```

1. Push your local repository to Heroku to build & deploy the application.  
    ```
    $ git push heroku master
    ```

1. Your application must be registered on the [Slack](https://api.slack.com/apps) and [Dropbox](https://www.dropbox.com/developers/apps) developer websites to acquire access to API endpoints.

  Once your application has been "created" on each developer platform, you will be able to retrieve tokens necessary for configuring several environmental variables on Heroku. All of these values can be found in the configuration pages on each developer platform.
  * DROPBOX_CLIENT_ID = Dropbox App Key
  * DROPBOX_CLIENT_SECRET = Dropbox App Secret
  * DROPBOX_REDIRECT_URI = [Heroku Application URL]/oauth2
  * SLACK_CLIENT_ID = Slack Client ID
  * SLACK_CLIENT_SECRET = Slack Client Secret
  * SLACK_VERIFICATION_TOKEN = Slack Verification Token

  A simple Heroku command can be used to set each variable.  
  ```
  $ heroku config:set [ENV_VARIABLE]=[VALUE]
  ```
  You may also want to set RESQUE_WEB_HTTP_BASIC_AUTH_PASSWORD to secure your resque web monitoring page from public access.

1. Complete additional configuration on Slack / Dropbox developer platforms.  
  1. Slack  
    * In the OAuth & Permissions tab, add **[Heroku Application URL]/oauth** to the Redirect URLs section.
    * In the Event Subscriptions tab, set the Request URL to **[Heroku Application URL]/events** and wait for verification to complete (your application must already be deployed to Heroku for this to work).
    * Also in the Event Subscriptions tab, add **file_shared** and **message.im** to the Bot Events section and click **Save Changes**.

  2. Dropbox  
    * Add **[Heroku Application URL]/oauth2** to the Redirect URIs section.

## Built With
* [Sinatra](http://www.sinatrarb.com/) — Rack-based web application framework
* [Postgres](https://www.postgresql.org/) — Database
* [Resque](https://github.com/resque/resque) / [Redis](https://redis.io/) — Job queue
* [Bootstrap](http://getbootstrap.com/) — HTML & CSS framework

## License
This project is licensed under the terms of the [MIT license](LICENSE.txt).

If you have any questions, don't hesitate to reach out to me — sean(dot)a(dot)mcgee(at)gmail(dot)com.

**DISCLAIMER:** Slurp is a hobby project and has not been audited for security. Slurp is not suited for applications involving the exchange of confidential / sensitive information. Use at your own risk. The author assumes no responsibility for any breaches that result from the use of Slurp.
