express = require 'express'
app 	= express()
swig 	= require 'swig'
fs 		= require 'fs'
url 	= require 'url'
zipok	= require('easy-zip').EasyZip
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


# Files cleaner
sanit = (file) ->
	file = file.replace(/\r/g, '').split('\n')
	i=-1
	while true
		i++
		break if (i or i+1) is file.length
		file[i] = file[i].trim()
		if file[i].replace(/([A-Z]|[a-z]|[А-Я]|[а-я]|\d|\ |\-|\.)/g, '').length > 0 or file[i].replace(/\ /g, '').length is 0
			file.splice i, 1
			i--
	if file.length == 0
		return []  
	res = {}
	res[file[key]] = file[key] for key in [0..file.length-1]
	value for key, value of res

# ROUTER
app.get '/', (req, res)->
	res.render 'index'

app.post '/uploadfiles', (req, res) ->
	file1 = sanit fs.readFileSync req.files.txt1.path, 'utf-8'
	file2 = sanit fs.readFileSync req.files.txt2.path, 'utf-8'
	match = []
	zip = new zipok()
	for one, i in file1
		flag = false
		match.push {one: one, mults: []}
		j=-1
		while(true)
			j++
			break if (j or j+1) is file2.length
			if file2[j].toLowerCase().indexOf(one.toLowerCase()) > -1
				if not flag
					folder = zip.folder one
					flag = true
				match[match.length-1].mults.push file2[j]
				folder.file file2[j]+'.txt', ''
				file2.splice j, 1
				j--
	folder = zip.folder 'Noname'
	for i in file2
		if file2[i] != undefined
			folder.file file2[i]+'.txt', ''
	zip.writeToFile './app/file.zip'
	csv './app/file.csv', match, file2
	res.json {status: 1}


app.get '/getcsv', (req, res) ->
	res.set 'Content-Type', 'application/octet-stream'
	res.setHeader 'Content-Disposition', 'attachment; filename=lines_parser.csv'
	readStream = fs.createReadStream './app/file.csv'
	readStream.pipe res

app.get '/getzip', (req, res) ->
	res.set 'Content-Type', 'application/zip'
	res.setHeader 'Content-Disposition', 'attachment; filename=lines_parser.zip'
	readStream = fs.createReadStream './app/file.zip'
	readStream.pipe res
	readStream.on 'end', () ->
		fex.remove './app/file.zip', (err) ->
			if not err then console.log 'file.zip killed'