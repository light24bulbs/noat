
request = require('supertest');
setup = require('./libs/setup')
expect = require('chai').expect
userLib = require('./libs/user')
userLib.createHooks()

session = 
mealKey = null
cardId = null
allPrograms = null
testCard = null
describe 'Meals', ->
	before (done) -> 
		Program.fetchAll().then (programs) ->
			allPrograms = programs
			program = programs.first()
			User.where(email: 'light24bulbs@gmail.com').fetch().then (user) ->
				Card.build {program_id: program.get('id'), balance: 5, user_id: user.get('id')}, (err, card) ->
					#if err? return done(err)
					testCard = card
					cardId = card.get('id')
					done()

	it 'should create a meal and return a token', (done) ->
		request.agent(app)
		.post('/meal/create').send(
			pos_secret:'123abc'
			meal: 
				price: 5.52, 
				programs: [allPrograms.first().get('client_id'), allPrograms.last().get('client_id')]
				location_id: 1,
				items: items: [{name: 'Burger', ratable: true}, {name: 'Milkshake', ratable: true}, {name: 'unratable item', ratable: false}]
		
		).expect(200)
		.end (err, res) ->
			console.log('created meal with response', res.body)
			mealKey = key = res.body.key
			new Meal().fetch().then (meal) ->
				console.log('retreived meal from database with attributes ', meal.attributes)
				expect(meal.get('key')).to.equal(key)
				done(err)

	it 'shouldnt create a meal if the POS key is wrong', (done) ->
		request.agent(app)
		.post('/meal/create').send(
			pos_secret:'wrongcode'
			meal: 
				price: 5.52, 
				restaurant_id: 1, 
				items: {test1:'test1', test2: {nested1: 'nested1', nested2: 'nested2'}}
		
		).expect(403)
		.end (err, res) ->
			console.log('created meal with response', res.body)
			done(err)

	it 'redeem', (done) ->
		this.timeout 10000
		Card.fetchAll().then (cards) ->
			console.log('found existing cards ', cards)			
			console.log('test attempting to redeem card id: ', cardId)
			userLib.login {}, (session, token) ->
				session
				.post('/card/redeem').send(
					token: token
					meal_key: mealKey
					id: cardId
					amount: 1
				).expect(200)
				.end (err, res) ->
					if err?
						return done(err)
					console.log('redeemed card with response', res.body)
					console.log('meal transactions: ', res.body.meal.transactions)
					expect(res.body.meal.balance).to.equal(res.body.meal.price - 1)
					Card.fetchAll().then (cards) ->
						console.log('redeemed card in db is: ', cards.first())
						done(err)

	it 'unredeem', (done) ->
		this.timeout 10000
		Card.fetchAll().then (cards) ->
			console.log('found existing cards ', cards)			
			console.log('test attempting to redeem card id: ', cardId)
			userLib.login {}, (session, token) ->
				session
				.post('/card/unredeem').send(
					token: token
					meal_key: mealKey
					id: cardId
				).expect(200)
				.end (err, res) ->
					if err?
						return done(err)
					console.log('unredeemed card with response', res.body)
					console.log('meal transactions: ', res.body.meal.transactions)
					expect(res.body.meal.balance).to.equal(Number(res.body.meal.price))
					Card.fetchAll().then (cards) ->
						console.log('redeemed card in db is: ', cards.first())
						done(err)


	it 'POS redeem', (done) ->
		this.timeout 10000
		
		userLib.login {}, (session, token) ->
			session
			.post('/card/redeem').send(
				pos_secret: '123abc'
				meal_key: mealKey
				number: testCard.get('number')
				amount: 1
			).expect(200)
			.end (err, res) ->
				console.log('pos redeem', res.body)
				if err?
					return done(err)
				console.log('redeemed card with response', res.body)
				console.log('meal transactions: ', res.body.meal.transactions)
				expect(res.body.meal.balance).to.equal(Math.round((res.body.meal.price - 1) * 100) / 100)
				Card.fetchAll().then (cards) ->
					console.log('redeemed card in db is: ', cards.first())
					done(err)

	it 'should update the meal', (done)	->
		this.timeout 10000

		request.agent(app)
		.post('/meal/update').send(
			pos_secret:'123abc'
			meal_key: mealKey
			meal: 
				price: 7.52, 
				items: {test1:'test1', test2: {nested1: 'nested1', nested2: 'nested2'}, newItem: 'an updated item'}
		
		).expect(200)
		.end (err, res) ->
			console.log('got res updating meal ', res.body)
			expect(res.body.balance).to.equal(res.body.price - 1)
			done(err)

	it 'should checkout the meal', (done) ->
		this.timeout 10000
		request.agent(app)
		.post('/meal/checkout').send(
			pos_secret:'123abc',
			meal_key: mealKey
		).expect(200).end (err, res) ->

			console.log('checked out with response ', res.body)
			Meal.fetchAll(withRelated: 'transactions.card').then (meals) ->
				console.log 'meal in database is ', meals.first().toJSON()
				done(err)

