Parse.initialize("lEf1qOOpwSfPKKDcOTPuFOxfZJa5ArkaCDRZqPpu", "EjE2ckFkTlQeYkBcMKJ41EUeV9ckvUfQqw5xqdpo");

var pw = 'testpw';//'pw'+Math.random();

var lastReload = null;

var app = angular.module('Squawk', []);
app.controller('Main', function($scope) {
	$scope.loggedIn = function() {
		return !!Parse.User.current();
	}
	$scope.loading = 0;
	$scope.verificationNumber = '(646) 576-7688';
	$scope.enteredNickname = function() {
		$scope.password = pw;
	}
	$scope.done = function() {
		$scope.loading++;
		Parse.Cloud.run('lookupUsernameByPassword', {password: $scope.password}, {
			success: function(username) {
				$scope.loading--;
				if (username) {
					Parse.User.logIn(username, $scope.password, {
						success: function() {
							// we did it.
							console.log("logged in");
							Parse.User.current().set('nickname', $scope.nickname);
							Parse.User.current().save();
							$scope.$digest();
						},
						error: function() {
							$scope.error = "Something went wrong";
							$scope.$digest();
						}
					});
				} else {
					$scope.didntReceiveTextYet = true;
				}
				$scope.$digest();
			},
			error: function() {
				console.log('error')
				$scope.error = "We couldn't connect to the Squawk server. Are you connected to the Internet?";
			}
		})
	}
	$scope.$watch($scope.loggedIn, function(loggedIn) {
		if (loggedIn) {
			$scope.reloadIfNeeded();
		}
	})
	$scope.reloadIfNeeded = function() {
		if (!lastReload || (Date.now())-lastReload > 60 * 5) {
			lastReload = Date.now();
			$scope.loading++;
			var q = new Parse.Query('Message');
			q.equalTo('recipient', Parse.User.current());
			q.descending('createdAt');
			q.include('sender');
			q.limit(30);
			q.find({
				success: function(squawks) {
					$scope.squawks = squawks;
					$scope.$digest();
				},
				error: function() {
					$scope.error = "No Internet connection";
					$scope.$digest();
				}
			})
		}
	}
})
