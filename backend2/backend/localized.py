
sent_you_a_squawk = {"en": "%s sent you a squawk."}
sent_you_and_one_other_a_squawk = {"en": "%s sent a squawk to you and 1 other person."}
sent_you_and_n_others_a_squawk = {"en": "%s sent a squawk to you and %i others."}
contact_joined_squawk = {"en": "Your contact %s just got Squawk. Why not say hi?"}

def localized_message(message_dict, user):
    preferred_langs = user.get('prefs', {}).get('languages', ['en'])+['en']
    for lang in preferred_langs:
        if lang in message_dict:
            return message_dict[lang]
    return message_dict.values()[0]
    
