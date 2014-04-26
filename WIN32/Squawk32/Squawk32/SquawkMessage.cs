using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Squawk32
{
    public class SquawkMessage
    {
        public byte[] audio; //the squawk's audio data

        public String sender; //the sender of the squawk

        public DateTime CreatedAt; //the time the squawk was created at

        public List<String> thread_members; //the intended recipients of the squawk

        public String id; //the id of the squawk

        /**
         * Creates a new Squawk with a given sound data and sender.
         */
        public SquawkMessage(String _sender, DateTime _date, List<String> _thread_members, String _id)
        {
            this.sender = _sender;
            this.CreatedAt = _date;
            this.thread_members = _thread_members;
            this.id = _id;
        }

        /**
         * Plays the Squawk
         * @return True if the sound was played, otherwise false.
         */ 
        public bool play()
        {
            //TODO: Logic for playing a squawk

            return false;
        }
    }
}
