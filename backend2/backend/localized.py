
def localized_message(message_dict, user):
    preferred_langs = user.get('prefs', {}).get('languages', ['en'])+['en']
    for lang in preferred_langs:
        if lang in message_dict:
            return message_dict['lang']
    return message_dict.values()[0]
    
