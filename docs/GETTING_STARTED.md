# Getting started with Metabase Automation !

Let's see how to setup your environment for using the Metabase Automation System.

## Requirements

* Online Metabase instance
* Username + Password able to connect on the instance
* Decidim Database already set on Metabase

## Let's start

1. Set the required environment variable  
Copy the file `.env.example` and rename it as `.env`. Once done, add your credentials and the metabase host. You must not add the metabase URL but the host only.

2. Create the main `config.yml` file  
This file is the global configuration of the project. It is used by the program to link local cards to the right Metabase database. Also, it allows to define the current locale and the decidim host.  

There is several keys in this file : 
```yaml
---
database:
  decidim_cards:
    name: <EXISTING METABASE DATABASE>
  matomo_cards:
    name: <EXISTING METABASE DATABASE>
collection_name: <NEW OR EXISTING METABASE COLLECTION>
language: fr # en
host: <HOST>
```
* `database` - Allows to link a cards folder to a Metabase database
  * In the example above, there is two keys `decidim_cards` and `matomo_cards`. These keys are the name of the folders present in `/cards`.
  * You must define at least one database. For example you can remove the database key `matomo_cards`.
  * You can find existing database in Metabase
* `collection_name` - Name of collection on Metabase.
  * If the collection doesn't exist, the program will create it. Otherwise it use the existing one.
  * You can find an existing collection name in Metabase
* `language` - Define the translation of cards in Metabase
  * Cards must contains the right translation to work as expected (see example [decidim users translations](../cards/decidim_cards/users/locales/en.yml))
  * If locale doesn't exist, default is English
* `host` - Decidim host for cards which depends on the current host for request
  * You can find this host in the __Metabase database > table Decidim Organizations > Host__

3. Install dependencies  
Run `bundle install`

4. Execute program
`bundle exec main.rb -v`

> To prevent multiple authentication for each execution, program will store a valid token in '/token.private'. If file doesn't exist or token is deprecated, program will refresh it. This file is ignored by git.  