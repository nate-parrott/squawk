
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

function randomKey() {
	return Math.random() + '_' + Math.random();
}

function userByPhoneNumber(phone, callback) {
	Parse.Cloud.useMasterKey();
	var phone = normalizePhoneNumber(phone);
	var query = new Parse.Query(Parse.User);
	query.equalTo('username', phone);
	query.find({
		success: function(objects) {
			var user;
			if (objects.length) {
				user = objects[0];
				callback(user);
			} else {
				user = new Parse.User();
				user.setUsername(phone);
				user.setPassword(randomKey());
				var acl = new Parse.ACL(user);
				acl.setPublicReadAccess(true);
				user.setACL(acl);
				user.save(null, {
					success: function() {
						callback(user);
					}
				});
			}
		}
	})
}

Parse.Cloud.define('getUserByPhone', function(request, response) {
	var phone = request.params.phoneNumber;
	userByPhoneNumber(phone, function(user) {
		response.success(user);
	})
});

Parse.Cloud.define('getUsersByPhone', function(request, response) {
	var q = new Parse.Query(Parse.User);
	q.containedIn('username', request.params.phoneNumbers.map(normalizePhoneNumber));
	q.find({
		success: function(users) {
			response.success(users);
		}
	})
});

Parse.Cloud.define("verify", function(request, response) {
	Parse.Cloud.useMasterKey();
	
	var phone = normalizePhoneNumber(request.params.From);
	var words = request.params.Body.split(' ');
	var pw = words[words.length-1].toLowerCase();
	
	userByPhoneNumber(phone, function(user) {
		user.setPassword(pw);
		user.save();

		var passwordMap = new Parse.Object('PasswordMap');
		passwordMap.set('password', pw);
		passwordMap.set('username', phone);
		passwordMap.save();

		response.success();
	});
});

function installationsForUser(user) {
	var installs = [];
	var check = {};
	var addInstall = function(inst) {
		if (!check[inst.id]) {
			installs.push(inst);
			check[inst.id] = true;
		}
	}
	if (user.get('installation')) {
		addInstall(user.get('installation'));
	}
	if (user.get('installations')) {
		user.get('installations').forEach(function(inst) {addInstall(inst)});
	}
	return installs;
}

Parse.Cloud.define("sendWelcome", function(req, res) {
		Parse.Cloud.useMasterKey();
	(new Parse.Query("Message")).equalTo('id2', '[WELCOME]').first({
		success: function(template) {
			var msg = new Parse.Object("Message");
			msg.set("recipient", req.user);
			["sender", "file"].forEach(function(key) {
				msg.set(key, template.get(key));
			})
			var acl = new Parse.ACL(req.user);
			msg.setACL(acl);
			msg.set("listened", false);
			msg.save();
			res.success('ok');
		},
		error: function(e) {
			res.error(e);
		}
	})
})

var joined = function(request, response) {
	Parse.Cloud.useMasterKey();

	var user = request.user;
	if (user.get('joined') && 0) {
		response.success(false);
	} else {
		var findFriends = new Parse.Query('UserContactsListing');
		findFriends.containsAll('contactPhoneNumbers', [user.get('username')]);
		findFriends.include('user');
		findFriends.limit(150);
		findFriends.find({
			success: function(friendEntries) {
				var installations = [];
				friendEntries.forEach(function(entry) {
					installations = installations.concat(installationsForUser(entry.get('user')));
				})
				var installationIDsToNotify = installations.map(function(inst) {return inst.id});

				var query = new Parse.Query(Parse.Installation);
				query.containedIn('objectId', installationIDsToNotify);
				var nickname = request.params.nickname;
				var message = "Your contact "+nickname+" ("+user.get('username')+") just got Squawk. Why not say hi?";
				var notif = {
					where: query,
					data: {
						alert: message,
						type: 'friendJoined',
						phone: user.get('username')
					}
				};
				Parse.Push.send(notif);

				user.set('joined', true);
				user.save();
				response.success(true)
			},
			error: function(err) {
				response.error(err);
			}
		})
	}
}
Parse.Cloud.define("joined", joined);

Parse.Cloud.define('lookupUsernameByPassword', function(request, response) {
	Parse.Cloud.useMasterKey();
	var password = request.params.password;
	var query = new Parse.Query('PasswordMap');
	query.equalTo('password', password);
	query.find({
		success: function(objects) {
			if (objects.length) {
				response.success(objects[0].get('username'));
			} else {
				response.success(null);
			}
		}
	})
})

Parse.Cloud.beforeSave("Message", function(request, response) {
	if (request.object.isNew()) {
		Parse.Cloud.useMasterKey();

		var id2 = (request.user? request.user.id + Math.random() : 'master'+Math.random());
		request.object.set('id2', id2);

		var recipient = request.object.get('recipient');
		var sender = request.object.get('sender');
		recipient.fetch({
			success: function() {
				sender.fetch({
					success: function() {
						var installations = installationsForUser(recipient);
						if (installations.length) {
							var query = new Parse.Query(Parse.Installation);
							query.containedIn('objectId', installations.map(function(install) {return install.id}));
							var message = sender.get('nickname')+" sent you a Squawk.";
							var notif = {
								where: query,
								data: {
									alert: message,
									badge: 'Increment',
									sound: 'squawk.m4a',
									type: 'message',
									//'content-available': '1',
									'id2': id2
								}
							};
							if (recipient.id == sender.id) {
								notif.data.badge = notif.data.sound = notif.data.alert = undefined;
							}
							Parse.Push.send(notif);
						}
						response.success();
					},
					error: function(obj, err) {
						console.error(err);
					}
				})
			}
		})
	} else {
		response.success();
	}
});

Parse.Cloud.define('confirm', function(request, response) {
	Parse.Cloud.useMasterKey();

	var fromPhone = request.params.from;

	var toPhones = request.params.toPhones? request.params.toPhones : [request.params.to]; // request.params.toPhones replaces request.params.to after b14
	var fromNickname = request.params.fromNickname;
	var query = new Parse.Query(Parse.User);
	query.containedIn('username', toPhones);
	query.find({
		success: function(users) {
			if (users.length) {
				var installations = [];
				users.forEach(function(recipientUser) {
					installations = installations.concat(installationsForUser(recipientUser));
				})
				var installationQuery = new Parse.Query(Parse.Installation);
				installationQuery.containedIn('objectId', installations.map(function(inst) {return inst.id}));
				var message = fromNickname + ": ✓";
				var notif = {
					where: installationQuery,
					data: {
						alert: message,
						sound: '',
						type: 'confirmation'
					}
				};
				Parse.Push.send(notif);
				response.success();
			} else {
				response.error("empty objects");
			}
		},
		error: function(e) {
			response.error(e);
		}
	})

});

function queryUsersOnSquawk() {
	var hasInstallations = (new Parse.Query(Parse.User)).exists('installations');
	return hasInstallations;
	//return hasInstallations;
	//var hasLegacyInstallation = (new Parse.Query(Parse.User)).exists('installation');
	//return Parse.Query.or(hasInstallations, hasLegacyInstallation);
}

Parse.Cloud.define('updateUserContactsListing', function(request, response) {
	Parse.Cloud.useMasterKey();
	(new Parse.Query('UserContactsListing')).equalTo('user', request.user).first({
		success: function(listing) {
			if (!listing) {
				listing = new Parse.Object('UserContactsListing');
				listing.set('user', request.user);
				listing.set('contactPhoneNumbers', []);
			}
			var numbers = listing.get('contactPhoneNumbers');
			if (request.params.reset) {
				numbers = [];
			}
			var alreadySeen = {};
			request.params.add.forEach(function(num) {
				if (!alreadySeen[num]) {
					alreadySeen[num] = true;
					numbers.push(num);
				}
			})
			listing.set('contactPhoneNumbers', numbers);
			listing.save();
			
			// return new friends that are on Squawk:
			var addedAndOnSquawk = queryUsersOnSquawk();
			addedAndOnSquawk.containedIn('username', request.params.add);
			addedAndOnSquawk.limit(1000);
			addedAndOnSquawk.find({
				success: function(results) {
					response.success(results.map(function(user) {return user.get('username')}));
				},
				error: function(error) {
					response.error(error);
				}
			})
		},
		error: function(error) {
			response.error(error);
		}
	})
})

Parse.Cloud.define('allFriendsOnSquawk', function(request, response) {
	Parse.Cloud.useMasterKey();
	(new Parse.Query("UserContactsListing")).equalTo('user', request.user).first({
		success: function(listing) {
			if (!listing) {
				response.error();
				return;
			}
			var contacts = listing.get('contactPhoneNumbers');
			var findFriends = queryUsersOnSquawk();
			findFriends.containedIn('username', contacts);
			findFriends.limit(1000);
			findFriends.find({
				success: function(results) {
					response.success(results.map(function(user) {return user.get('username')}));
				},
				error: function(error) {
					response.error(error);
				}
			})
		},
		error: function(err) {
			response.error(err);
		}
	})
})

// DEPRECATED ENDPOINTS:

// used until 1.0b14:
Parse.Cloud.define("notifyFriends", joined);

// used before 1.0b8:
Parse.Cloud.define('checkPhoneNumbers', function(request, response) {
	var start = Date.now();
	var q = new Parse.Query(Parse.User);
	var numbers = request.params.numbers.split("|");
	q.containedIn('username', numbers);
	q.exists('installation');
	q.limit(1000);
	q.find({
		success: function(objects) {
			var indices = [];
			objects.forEach(function(user) {
				var number = user.get('username');
				var i = numbers.indexOf(number);
				if (i != -1) {
					indices.push(i);
				}
			});
			console.log("Looking up "+numbers.length+" numbers took "+((Date.now()-start)/1000)+" seconds");
			response.success(indices);
		},
		error: function(e) {
			response.error(e);
		}
	})
});


