var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
  if (!res.locals.broken) {
    // APP_VERSION is set by the Kubernetes deployment to the Jenkins build number
    res.render('index', { title: 'Express', version: process.env.APP_VERSION || 'local' });
  } else {
  	res.status(500).send('Something broke!');
  }
});

module.exports = router;
