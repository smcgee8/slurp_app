# ![slurp_app](public/img/LogoBig.png)

## Synopsis
Slurp makes life easier for teams who use Slack to communicate and Dropbox to store files. Simply invite the Slurp bot to any Slack channel and it will automatically copy any files posted there to its designated Dropbox folder.

## Usage
The project is currently deployed at https://sheltered-bastion-69963.herokuapp.com/ (it may take the page ~5-10 seconds to load if the app is currently idle). Anyone who wishes to install it for their team may do so there by clicking "Add to Slack".

Once Slurp has been added to your Slack team, the Slurp bot will send you a direct message with a link to connect Slurp to your Dropbox account.

Once setup is complete, the Slurp bot can be invited to any channel in Slack to begin indexing files posted to that channel:
```
/invite @slurp
```
Files will be stored on the connected Dropbox account:
```
'/Slurp App/[Team Name]/[Channel Name]'.
```
You may wish for Slurp to index files posted to a channel prior to inviting the bot to that channel. Sending 'update all' to the Slurp bot as a direct message will fully index the files in all channels the Slurp bot is currently a member of.



## Deployment

## Built With

## Usage & License
