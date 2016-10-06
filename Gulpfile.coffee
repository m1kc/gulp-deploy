gulp = require 'gulp'
chalk = require 'chalk'

GulpSSH = require 'gulp-ssh'
shell = require 'gulp-shell'
moment = require 'moment'
gulpSSH = null

sshHost = 'myserver.example.com'
sshPort = 22
sshLogin = 'webdeploy'
deploy_password = null

archiveName = 'deploy.tgz'
timestamp = moment().format('YYYYMMDDHHmmssSSS')
buildPath = './dist'
rootPath = '/srv/web/dashboard.total.comearth.ru/'
releasesPath = rootPath + 'releases/'
symlinkPath = rootPath + 'current'
releasePath = releasesPath + timestamp


gulp.task 'default', ->
	console.log """

This is the general-purpose gulp deploy script.
Written by m1kc in 2016.
https://github.com/m1kc/gulp-deploy

Type #{chalk.blue 'gulp deploy'} to deploy your stuff.

Current config (change in Gulpfile):
- buildPath:    #{buildPath}
- rootPath:     #{rootPath}
- releasesPath: #{releasesPath}
- symlinkPath:  #{symlinkPath}
- sshHost:      #{sshHost}
- sshPort:      #{sshPort}
- sshLogin:     #{sshLogin}

SSH password will be read from DEPLOY_PASSWORD env
or you'll be prompted to type it into tty.

"""


gulp.task 'deploy:passwd', ->
	if process.env.DEPLOY_PASSWORD?
		deploy_password = process.env.DEPLOY_PASSWORD
	else
		inquirer = require 'inquirer'
		return inquirer
			.prompt [{type: 'password', name: 'passwd', message: 'SSH password:'}]
			.then (answers) ->
				deploy_password = answers.passwd

gulp.task 'deploy:connect', ['deploy:passwd'], ->
	console.log "Using password: #{deploy_password}"
	gulpSSH = new GulpSSH {
		ignoreErrors: false
		sshConfig:
			host: sshHost
			port: sshPort
			username: sshLogin
			password: deploy_password
	}

gulp.task 'deploy:compress', ['deploy:connect'],
	shell.task("tar -czvf ./" + archiveName + " --directory=" + buildPath + " .")

gulp.task 'deploy:prepare', ['deploy:connect'], ->
	return gulpSSH.exec("cd " + releasesPath + " && mkdir " + timestamp);

gulp.task 'deploy:upload', ['deploy:prepare', 'deploy:compress'], ->
	return gulp
		.src(archiveName)
		.pipe(gulpSSH.sftp('write', releasePath + '/' + archiveName))

gulp.task 'deploy:uncompress', ['deploy:upload'], ->
	return gulpSSH.exec("cd " + releasePath + " && tar -xzvmf " + archiveName);

gulp.task 'deploy:symlink', ['deploy:uncompress'], ->
	return gulpSSH.exec("rm " + symlinkPath + " &&" + " ln -s " + releasePath + " " + symlinkPath);

gulp.task('deploy:clean', ['deploy:symlink'], shell.task('rm ' + archiveName, {ignoreErrors: true}));

gulp.task 'deploy', [
	'deploy:connect'
	'deploy:compress'
	'deploy:prepare'
	'deploy:upload'
	'deploy:uncompress'
	'deploy:symlink'
	'deploy:clean'
]
