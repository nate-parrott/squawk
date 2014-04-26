Squawk API Documentation
=========================

It's so fucking advanced
--------------------------

**All methods are GET or POST requests to api.squawkwith.us.**

Requests are composed of an endpoint (path), like *http://api.squawkwith.us/squawks/recent*, and a JSON dictionary of arguments, like {"message": "hello, world"}. The JSON dictionary is percent-encoded, and appended to the endpoint, with a "?args=" in-between. **All messages are GET unless specified.**

For example, to send a request to a hypothetical endpoint called send_message, we take the URL `http://api.squawkwith.us/send_message` and the arguments `{"message": "hey"}`. We percent-encode the arguments, producing `%7B%22message%22%3A%20%22hey%22%7D`. We append `?args=` and then this string to the URL, producing the final url, `http://api.squawkwith.us/send_message?args=%7B%22message%22%3A%20%22hey%22%7D`.

Logging in
-------------

Generate a random key. Get the user to send a text to our Twilio #, making sure your key is the last word in the text (separated from the rest of the text by a space). When they're done, try to log in by calling `/make_token` with the argument `{secret: <your key>}`. You'll get JSON back. If you get a dictionary with `{success: true}`, the text has been received and the login is successful. The dictionary will then have two extra keys: `phone` and `token`. `phone` is the user's phone number, which is used as their username. `token` is a login token, which you must pass as a the key `token` in the args dictionary for every subsequent request which requires logging in.

Other requests
===================

*All the following requests require that you be signed in. In your args dictionary, you must have a key `token` set to the value you got back when you called `/make_token`.*

Retrieving squawks
--------------------

 **Get a list of recent squawks you've received** by calling `/squawks/recent`, which takes no arguments except the login token, and returns a JSON dictionary: `{success: true/false, results: [a JSON array of squawks]}`. Each squawk is a dictionary containing at least the keys `{sender: <phone #>, thread_members: <all phone #s in the thread, including the sender and current recipient>, _id: <a unique ID>, date: <a unix timestamp>}`.

**Play back a squawk** by loading the data from `/squawks/serve`, and passing the arg dictionary `{id: <the value of the squawk's _id field}`, plus a login token. _Note it's `_id` in the Squawk dictionary, but `id` when used as an argument to the API.

**Mark a squawk as listened** by calling `/squawks/listened`, and again including the `_id` field of the squawk in the args dictionary with the key `id`.

Sending squawks
------------------

_ **When dealing with phone numbers**, make sure to always *normalize* them by stripping all non-digits, and appending a country code of `1` to all 10-digit US phone numbers. An example implementation can be found on [GitHub](https://github.com/wcthompson/squawk/blob/master/backend2/backend/util.py)_

**Send a squawk** by making a POST request to `/squawks/send` with the args `{recipients: [<array of phone #s>], filename: <an arbitrary filename, preferably with an extension indicating the file type>}`. In addition, POST the contents of the file as the POST body, making sure the `Content-Type` of the request is `application/octet-stream`.

Determining friends on squawk
-------------------------------

When the user finishes signup, you'll want to **send pushes to all the people who have them in their contacts** by calling `/notify_friends`.

To do this, the server must keep track of each user's contacts. So, when you first fetch the contacts of the user (and whenever the user gets new contacts), you'll want to **update the contacts list on the server** make a POST request to `/register_contacts`. The only arg is a login token, but send a JSON dictionary as the post body. This contains `{contact_phones: [<an array>], contact_names: [<an array>]}`. `contact_phones` holds all the phone #s of every new contact, and `contact_names` holds their names *in the same order.* (The arrays should be the same length.) Again, make sure `Content-Type: application/octet-stream`.

The user will get push notifications every time a contact joins. However, push notifications don't always make it, so you might want to **check which friends are signed up** every day or so, as well as **immediately upon signup**. To do this, call `/check_contacts_signed_up`. If it's successful, you'll get back a dictionary `{phones: [<array of phones #s>]}`.

You'll **also** want to let the user know *immediately* if they send a Squawk to someone who isn't signed up. After a squawk is sent, call `/which_users_not_signed_up` with an arg `phones`, an array containing the phone #s of the people you just Squawked. You'll get back a dictionary containing a key `users_not_signed_up`. The phone numbers in this array aren't signed up, so let the user know. You'll probably want to prompt the user to invite their friends, and text them an invite with a link to `come.squawkwith.us`.

Push notifications
------------------

Right now, push notifications are only sent via *APNs,* but the push system is designed to be extensible to multiple platforms. On iOS, the client calls `/register_push_token` with the args `{token: <the user's LOGIN TOKEN>, type: <the user's platform-- now only 'ios' is supported>, push_token: <some string that the push service uses to identify the target device; on iOS, this is the device's hex-encoded push token>}`.

**When push notifications are received**, they'll come with special keys containing data about the type of notification. They'll have a `type` key, which can currently be either `message` or `friend_joined`. `message` notifications contain a `squawk_id` parameter, so the app can pre-download the audio data. `friend_joined` notifications always include the `phone` of the new user.

Checkmarks
------------

After the user listens to a Squawk, they may want to send a checkmark. To send a checkmark, POST to `/send_checkmark`, passing in an arg called `recipients`, an array of phone numbers to send to. If the user listens to a group squawk, you'll want to send checkmarks to everyone in the conversation. **This API will also accept GET requests which do the same thing, but those are deprecated. Please don't use them.**

The Squawk Robot
------------------

When you call `/notify_friends` and you haven't signed up with this phone # before, you may immediately receive a squawk from 00000000000 (11 zeroes). Display this as the 'Squawk Robot.' Other than that, it's a normal phone number.

Also, display the 00000000001 as *Squawk Feedback.*

