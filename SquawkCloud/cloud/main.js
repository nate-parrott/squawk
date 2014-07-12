
var twilioClient = require('twilio')('AC21dbc6f0d3908887e997d24c547b0e73', 'f420371278ad1693cf9432c332462738');

var express = require('express');
var app = express();

app.use(express.bodyParser());
app.post('/sendInvitation', function(req, res) {
    if (req.body.updates) {
        var MailingList = Parse.Object.extend("MailingList");
        var entry = new MailingList();
        entry.set("updatesOn", req.body.updates);
        entry.set("contact", req.body.phoneNumber); // it's called phoneNumber, but could also be an email
        entry.save();
        res.end("okay");
    } else {
        // send a text immediately:
    	var phone = req.body.phoneNumber;
    	twilioClient.sendSms({
    		to: phone,
    		from: "+16465767688",
    		body: "Download Squawk here: http://come.squawkwith.us",
    	}, function(err, response) {
    		if (err) {
    			console.log(err);
    			res.end("error");
    		} else {
    			res.end("okay");
    		}
    	});
    }
});

app.listen();

function normalizePhoneNumber(phone) {
	var allowed = '0123456789';
	var normal = "";
	for (var i=0; i<phone.length; i++) {
		var c = phone[i];
		if (allowed.indexOf(c) > -1) {
			normal += c;
		}
	}
	if (normal.length == 10) normal = "1"+normal;
	return normal; 
}

Parse.Cloud.define('sendInvitation', function(request, response) {
	var phone = request.params.phoneNumber;
	twilioClient.sendSms({
		to: phone,
		from: "+16465767688",
		body: "Download Squawk here: http://come.squawkwith.us?n="+normalizePhoneNumber(phone),
	}, function(err, response) {
		if (err) {
			console.log(err);
			response.failure("error");
		} else {
			response.success("okay");
		}
	});
})
