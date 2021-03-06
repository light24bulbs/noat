ConnectRoles = require('connect-roles');


module.exports = (app) ->

	global.roles = new ConnectRoles(
		failureHandler: (req, res, action) ->
			console.log('roles failed', req.user)
			# optional function to customise code that runs when
			# user fails authorisation
			if req.user? and !req.user.get('active')
				res.send(403, {name: 'authErr', message: 'Account Disabled', token: 'Account Disabled'})
			else
				res.send(403, {name: 'permErr', message: 'Access Denied - You don\'t have permission for: ' + action, token: 'Insufficient Roles'})

			#async: true
	)

	app.use(roles.middleware())

	roles.use 'logged in', loggedIn


	roles.use 'admin', (req) -> 
		if req.user? and req.user.get('admin') == true 
			return true

		
loggedIn = (req) ->
	console.log('checking for logged in user ', req.user)
	req.user? and req.user.get('active')

POS = (req) ->
	req.body.pos_secret == (process.env.POS_SECRET || '123abc')