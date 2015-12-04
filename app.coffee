express = require 'express'
app 	= express()
swig 	= require 'swig'
fs 		= require 'fs'
url 	= require 'url'
zipok 	= require('easy-zip').EasyZip
fex		= require 'fs-extra'

app.listen 8055

# MIDDLEWARE
app.engine 'html', swig.renderFile
app.set 'views', './app/temps'
app.set 'view engine', 'html'

app.use express.static './app/public'
app.use express.json()
app.use express.urlencoded()
app.use express.cookieParser()
app.use express.bodyParser()
app.use app.router

# CSV FILE MAKER
csv = (file, match, usent) ->
	fs.writeFileSync file, ''
	fs.appendFileSync file, '"Слова","Словосочетания"\n\n'
	for m in match
		fs.appendFileSync file, '"'+m.one+'"'
		for l, i in m.mults
			fs.appendFileSync file, ',"'+l+'"'
		fs.appendFileSync file, '\n'
	
	fs.appendFileSync file, '\n\n"Неиспользованные словосочетания"\n'
	for u, i in usent
		fs.appendFileSync file, '"'+u+'"'
		if i+1 < usent.length
			fs.appendFileSync file, '\n'

# ROUTER
app.get '/', (req, res)->
	res.render 'index'

app.post '/uploadfiles', (req, res) ->
	file1 = fs.readFileSync(req.files.txt1.path, 'utf-8').split('\n')
	file2 = fs.readFileSync(req.files.txt2.path, 'utf-8').split('\n')
	match = []
	usent = []
	for one, i in file1
		match.push {one: one, mults: []}
		for mul, j in file2
			
			for word in mul.split ' '
				if one is word
					match[match.length-1].mults.push mul
					file2[j] = '®'
	for m in match
		if not fs.existsSync './app/result/'+m.one then fs.mkdirSync './app/result/'+m.one
		for mul in m.mults
			fs.closeSync fs.openSync './app/result/'+m.one+'/'+mul+'.txt', 'w'
	zip = new zipok()
	zip.zipFolder './app/result/',() ->
		zip.writeToFile './app/file.zip'
	fex.emptyDir './app/result/', (err) ->
		if not err then console.log 'result folder empty'
	for mul, j in file2
		if mul != '®' then usent.push mul
	csv './app/file.csv', match, usent
	res.json {status: 1}


app.get '/getcsv', (req, res) ->
	res.set 'Content-Type', 'application/octet-stream'
	res.setHeader 'Content-Disposition', 'attachment; filename=lines_parser.csv'
	readStream = fs.createReadStream('./app/file.csv')
	readStream.pipe(res)

app.get '/getzip', (req, res) ->
	res.set 'Content-Type', 'application/octet-stream'
	res.setHeader 'Content-Disposition', 'attachment; filename=lines_parser.zip'
	readStream = fs.createReadStream('./app/file.zip')
	readStream.pipe(res)
	fex.remove './app/file.zip', (err) ->
		if not err then console.log 'file.zip killed'