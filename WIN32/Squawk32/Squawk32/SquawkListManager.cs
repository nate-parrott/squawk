using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Collections.ObjectModel;
using Microsoft.Phone.UserData;

namespace Squawk32
{
    public class Squawker : IComparable
    {
        public Contact contact = null;
        public List<SquawkMessage> squawks = new List<SquawkMessage>();

        public DateTime mostRecentSquawk()
        {
            return squawks.Count > 0 ? (DateTime)squawks[0].CreatedAt : DateTime.MinValue;
        }


        public string displayName
        {
            get
            {
                if (contact != null && contact.DisplayName != null)
                {
                    return contact.DisplayName;
                }
                if (squawks.Count > 0)
                {
                   // String user = (ParseUser)squawks[0]["sender"];
                   // return (string)user["username"];
                    return squawks[0].sender;
                }
                return "[unknown name]";
            }
        }

        public int CompareTo(object otherObj)
        {
            if (otherObj == null) return -1;
            Squawker other = otherObj as Squawker;
            if (other == null) throw new ArgumentException("Tried comparing a Squawker to another kind of object.");
            int c = other.mostRecentSquawk().CompareTo(mostRecentSquawk());
            if (c != 0)
            {
                c = other.displayName.CompareTo(displayName);
            }
            return c;
        }

        public static string normalizePhoneNumber(ContactPhoneNumber number)
        {
            string allowed = "0123456789";
            string normalized = "";
            string raw = number.PhoneNumber;
            for (int i = 0; i < raw.Length; i++)
            {
                string c = raw.Substring(i, 1);
                if (allowed.Contains(c))
                {
                    normalized += c;
                }
            }
            if (normalized.Length == 10) normalized = "1" + normalized;
            return normalized;
        }
    }

    public class SquawkListManager
    {
        private static async Task<IEnumerable<Contact>> getContacts()
        {
            Contacts contacts = new Contacts();
            var taskCompletionSource = new TaskCompletionSource<IEnumerable<Contact>>();
            EventHandler<ContactsSearchEventArgs> handler = null;
            handler = (s, e) =>
            {
                contacts.SearchCompleted -= handler;
                taskCompletionSource.TrySetResult(e.Results);
            };
            contacts.SearchCompleted += handler;
            contacts.SearchAsync("", FilterKind.None, null);
            return await taskCompletionSource.Task;
        }

        public static async Task<IEnumerable<Squawker>> reload()
        {
            System.Diagnostics.Debug.WriteLine("Reloading squawks... ");
            IEnumerable<Contact> contacts = await getContacts();
            IEnumerable<SquawkMessage> recentSquawks = await SquawkInterface.getSharedInterface().loadRecentSquawks();

            var squawkersForPhoneNumbers = new Dictionary<string, Squawker>();
            foreach (Contact contact in contacts)
            {
                Squawker squawker = new Squawker();
                squawker.contact = contact;
                foreach (ContactPhoneNumber number in contact.PhoneNumbers)
                {
                    squawkersForPhoneNumbers[Squawker.normalizePhoneNumber(number)] = squawker;
                }
            }
            foreach (SquawkMessage squawk in recentSquawks)
            {
                String sender = squawk.sender;
                Squawker squawker = null;
                if (squawkersForPhoneNumbers.ContainsKey(sender))
                {
                    squawker = squawkersForPhoneNumbers[sender];
                }
                else
                {
                    squawker = new Squawker();
                    squawkersForPhoneNumbers[sender] = squawker;
                }
                squawker.squawks.Add(squawk);
            }
            HashSet<Squawker> allSquawkers = new HashSet<Squawker>(squawkersForPhoneNumbers.Values);
            List<Squawker> sortedSquawkers = new List<Squawker>(allSquawkers);
            sortedSquawkers.Sort();
            return sortedSquawkers;
        }
    }
}
