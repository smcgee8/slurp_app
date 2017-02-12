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
You may wish for Slurp to index files posted to a channel prior to inviting the bot to that channel. Sending **'update all'** to the Slurp bot as a direct message will fully index the files in all channels the Slurp bot is currently a member of.

## Deployment
Slurp can be modified & independently deployed easily using Heroku.

1. Clone the repository (or your own fork) to create a local copy.
  ```
  $ git clone https://github.com/USERNAME/REPOSITORY
  ```
2. Create a new Heroku application with the appropriate add-ons.
```
$ heroku create
$ heroku addons:create heroku-postgresql:hobby-dev
$ heroku addons:create heroku-redis:hobby-dev
```
3. Configure environmental variables on Heroku.
```
$ heroku config:set [ENV_VARIABLE]=[VALUE]
```
Some environmental variables are set automatically (e.g. DATABASE_URL), but the following variables will need to be set by you:
* DROPBOX_CLIENT_ID
* DROPBOX_CLIENT_SECRET
* DROPBOX_REDIRECT_URI
* SLACK_CLIENT_ID
* SLACK_CLIENT_SECRET
* SLACK_VERIFICATION_TOKEN

Push local repository to Heroku to build & deploy application
```
$ git push heroku master
```



## Built With
* [Sinatra](http://www.sinatrarb.com/) — Rack-based web application framework
* [Postgres](https://www.postgresql.org/) — Database
* [Resque](https://github.com/resque/resque) / [Redis](https://redis.io/) — Job queue
* [Bootstrap](http://getbootstrap.com/) — HTML & CSS framework

## Usage & License
