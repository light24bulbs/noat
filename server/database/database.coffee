#should probably switch to some appdir var instead of relative pathing
adapters = require('../../knexfile')

env = process.env.NODE_ENV || "development"

###
adapter = {
	"development": adapters.development
	"test": adapters.test
	"production": adapters.production
}
###
console.log(adapters[env]);

class Database
	constructor: () ->
		@knex = require('knex')(adapters[env])
		@bookshelf = require('bookshelf')(@knex)
		@bookshelf.plugin('virtuals')
		@bookshelf.plugin('visibility')
		#console.log(@bookshelf)
		@models = {
			#should probably just batch load everything in the folder
			user: require('./../models/user')(@bookshelf)
			token: require('./../models/token')(@bookshelf)
			authentication: require('../opt/sublime_text/sublime_text /models/authentication')(@bookshelf)

		}
		console.log("Database connected")






#connect the db the first time it is required by server.coffee
db = new Database()

module.exports = db