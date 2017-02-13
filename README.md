# ![slurp_app](public/img/LogoBig.png)

## Synopsis
Slurp makes life easier for teams who use Slack to communicate and Dropbox to store files. Simply invite the Slurp bot to any Slack channel and it will automatically copy any files posted there to its designated Dropbox folder.

## Usage
The project is currently deployed at https://sheltered-bastion-69963.herokuapp.com/ (it may take the page ~5-10 seconds to load if the app is currently idle). Anyone who wishes to install it for their team may do so there by clicking **Add to Slack**.

Once Slurp has been added to your Slack team, the Slurp bot will send you a direct message with a link to connect Slurp to your Dropbox account.

After completing setup, the Slurp bot can be invited to any channel in Slack to begin indexing files posted to that channel.
```
/invite @slurp
```
Files will be stored on the connected Dropbox account in a folder created by Slurp.
```
/Slurp App/[TEAM NAME]/[CHANNEL NAME]
```
You may wish for Slurp to index files posted to a channel prior to inviting the bot to that channel. Sending **'update all'** to the Slurp bot as a direct message will fully index files in all channels the Slurp bot is currently a member of (including the full file history).

## Deployment
Slurp can also be modified & independently deployed easily using Heroku.

1. Clone the repository (or your own fork) to create a local copy.  
  ```
  $ git clone https://github.com/[USERNAME]/[REPOSITORY]
  ```

1. Create a new Heroku application with the appropriate add-ons.  
  ```
  $ heroku create
  $ heroku addons:create heroku-postgresql:hobby-dev
  $ heroku addons:create heroku-redis:hobby-dev
  ```

1. Push local repository to Heroku to build & deploy application.  
    ```
    $ git push heroku master
    ```

1. Create developer applications on [Slack](https://api.slack.com/apps) and [Dropbox](https://www.dropbox.com/developers/apps) API websites to acquire access to endpoints for the two platforms.

1. Once the API applications have been created, you will be able to access several tokens necessary to configure environmental variables on Heroku. The following variables will need to be set by you (all can be found in the configuration pages of your Slack/Dropbox appications):  
  * DROPBOX_CLIENT_ID — Dropbox App Key
  * DROPBOX_CLIENT_SECRET — Dropbox App Secret
  * DROPBOX_REDIRECT_URI — [Heroku Application URL]/oauth2
  * SLACK_CLIENT_ID — Slack Client ID
  * SLACK_CLIENT_SECRET — Slack Client Secret
  * SLACK_VERIFICATION_TOKEN — Slack Verification Token  
  
  ```
  $ heroku config:set [ENV_VARIABLE]=[VALUE]
  ```

1. Return to the Slack & Dropbox developer application configuration sites to complete setup.  
  1. Slack Application Configuration  
    * In the **OAuth & Permissions** tab, add **[Heroku Application URL]/oauth** to the **Redirect URLs** section.
    * In the **Event Subscriptions** tab, set the **Request URL** to **[Heroku Application URL]/events** and wait for verification to complete (your application must be deployed to Heroku for this to work).
    * Also in the **Event Subscriptions** tab, add **file_shared** and **message.im** to the **Bot Events** section and click **Save Changes**

  2. Dropbox Application Configuration  
    * Add **[Heroku Application URL]/oauth2** to the 'Redirect URIs' section.

## Built With
* [Sinatra](http://www.sinatrarb.com/) — Rack-based web application framework
* [Postgres](https://www.postgresql.org/) — Database
* [Resque](https://github.com/resque/resque) / [Redis](https://redis.io/) — Job queue
* [Bootstrap](http://getbootstrap.com/) — HTML & CSS framework

## Usage & License
**DISCLAIMER:** Slurp is a hobby project and has not been audited for security. Slurp is not suited for applications involving the exchange of confidential / sensitive information. Use at your own risk. The author assumes no responsibility for any data breaches that result from the use of Slurp.
