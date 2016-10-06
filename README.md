gulp-deploy
===========

A gulp script to deploy your stuff over SSH. Keeps a history of previous
deploys so you can easily rollback if something goes wrong. Use it
as standalone or embed it into your project's Gulpfile.

To start using it:
1. Create a SSH account on target server and give it permissions to write into
   target directory.
2. Make sure you web server serves content from the `current/` dir.
3. Open the target directory and `touch current && mkdir releases/`.
4. Tweak the Gulpfile settings.

Based on esender's script:
http://esender.me/2016/01/13/simply-deploy-with-gulp.html

Actually used in production since Feb 2016.
