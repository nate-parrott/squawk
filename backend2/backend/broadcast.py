from backend import db
import squawk

EVERYONE_NUMBER = "01010101010" # special # used to send a squawk to everyone

def recipients_for_broadcasts_from(sender):
    contact_listing = db.contact_listings.find_one({"phone": sender})
    if contact_listing:
        phones_in_sender_contacts = set(contact_listing['contact_phones'])
        return [recipient for recipient in phones_in_sender_contacts if squawk.name_in_contacts(sender,recipient)!=None and recipient!=sender]
    return []
