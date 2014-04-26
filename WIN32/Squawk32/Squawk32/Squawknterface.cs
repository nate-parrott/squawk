using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.IO;
using System.Threading.Tasks;
using System.IO.IsolatedStorage;
using Newtonsoft.Json;
using Windows.Storage;

namespace Squawk32
{
    public interface SquawkInterfaceProtocol
    {
        void userDidLogin();
    }

    class SquawkInterface
    {
        public int userLoggedInAlready = -1;

        private static SquawkInterface sharedInstance = new SquawkInterface();

        private bool isLoggedInVariable = false;  //a temporary best-approximation variable 

        public SquawkInterfaceProtocol messageDelegate; //the squawk interface delegate

        public String currentToken;
        /**
         * Gets the last used token
         **/
        public async Task<String> getLastUsedToken()
        {
            try
            {

                String token = await ReadData("monkey.txt");

                if (token != null && token != "")
                {
                    return token;
                }
                else
                {
                    return null;
                }
               
            }
            catch (Exception e)
            {
                return null;
            }


        }

        /**
         * Saves a token
         * @param token The token to save
         **/
        public async Task<bool> saveToken(String token)
        {
            try
            {
                WriteData("monkey.txt", token);
                return true;
            }
            catch (Exception e)
            {
                System.Diagnostics.Debug.WriteLine("Error during saveToken(): " + e.ToString());
                return false;
            }
        }
   
        /**
         * Returns a reference to the shared Squawk interface manager
         * 
         */
        public static SquawkInterface getSharedInterface()
        {
            return sharedInstance;
        }

        public static String apiPrefix = "http://api.squawkwith.us";

        /**
         * Downloads and loads a Squawk
         * @return A squawkmessage object
         */
        public async Task<SquawkMessage> getMessageForID(int someID)
        {

            return null;
        }

        /**
         *  Sends a request to the Squawk API with a given JSON dictionary 
         *  @precondition The JSONDict need not be serialized. Encoding will take place in the function
         */
        public async Task<String> queryAPIWithEndpoint(String endPoint, String JSONDict)
        {


            return null;

        }

        /**
         * Uploads a Squawk to the server, given the file's data.
         * @return True if the squawk uploaded, otherwise false.
         */
        public async Task<String> uploadSquawkWithData(byte[] data)
        {
            return null;
        }

        /**
         * Uploads a Squawk to the server, given a file path.
         * @return True if the squawk uploaded, otherwise false.
         */
        public async Task<bool> uploadSquawkFromFile(String filePath)
        {
            return false;
        }

        public async Task<bool> uploadSquawkFromDefaultFile()
        {
            //loads from the default file and sends 


            return false;
        }



        /**
         * Attempts to fetch new Squawks for the currently signed in account.
         * @return The number of new Squawks (>= 0)
         * @mutation Updates the list of new squawks for the current squawk user
         */
        public async Task<int> fetchNewMessages(){

            return -1;

        }


        class LoginResponse
        {
            public String phone;

            public String token;

            public bool success;

            public String error;
        }


        /**
         * Tries to log in the user with a supplied token
         * @return True if the user was succesfully logged in, otherwise false.
         */
        public async Task<bool> tryUserLoginWithSecret(String secret)
        {

            System.Diagnostics.Debug.WriteLine("Hey there");

            String endPoint = apiPrefix + "/make_token?args=";

            //generate the GET request

            String request = endPoint + WebUtility.UrlEncode("{\"secret\" : \"" + secret + "\"}");

            System.Diagnostics.Debug.WriteLine(request);

            WebClient client = new WebClient();
            string response;
            try
            {
                response = await client.DownloadStringTaskAsync(new Uri(request));
            }
            catch (System.Net.WebException e)
            {
                System.Diagnostics.Debug.WriteLine("Caught an exception: " + e.ToString());
                return false;
            }
            catch (System.IO.FileNotFoundException e2)
            {
                System.Diagnostics.Debug.WriteLine("Error: Remote server couldn't fetch that file: " + e2.ToString());
                return false;
            }
            //parse response.

            System.Diagnostics.Debug.WriteLine("Received Response: " + response);

            LoginResponse answer = JsonConvert.DeserializeObject<LoginResponse>(response);

            if (answer.error != null && answer.error != "")
            {
                System.Diagnostics.Debug.WriteLine("Error: " + answer.error);
                return false;
            }

            System.Diagnostics.Debug.WriteLine("Phone: " + answer.phone);
            System.Diagnostics.Debug.WriteLine("Token: " + answer.token);

            //save the login...
            await saveToken(answer.token);
            //IsolatedStorageSettings.ApplicationSettings.Add("token", answer.token);
            //IsolatedStorageSettings.ApplicationSettings.Add("phone", answer.phone);

            return answer.success;
        }


        /**
         * Returns true if the user is logged in, otherwise false
         * 
         **/
        public void isUserLoggedInCallback()
        {
            //try to load the last user key
            getLastUsedToken().ContinueWith(t =>
            {
                string x = t.Result;
                if (x != null && x != "")
                {
                    messageDelegate.userDidLogin();
                }
            }, TaskScheduler.FromCurrentSynchronizationContext());
        }


        async void WriteData(string fileName, string content)
        {
            byte[] data = Encoding.UTF8.GetBytes(content);

            StorageFolder folder = ApplicationData.Current.LocalFolder;
            StorageFile file = await folder.CreateFileAsync(fileName, CreationCollisionOption.ReplaceExisting);

            using (Stream s = await file.OpenStreamForWriteAsync())
            {
                await s.WriteAsync(data, 0, data.Length);
            }
        }

        async Task<string> ReadData(string fileName)
        {
            byte[] data;

            StorageFolder folder = ApplicationData.Current.LocalFolder;

            StorageFile file = await folder.GetFileAsync(fileName);

            using (Stream s = await file.OpenStreamForReadAsync())
            {
                data = new byte[s.Length];
                await s.ReadAsync(data, 0, (int)s.Length);
            }

            return Encoding.UTF8.GetString(data, 0, data.Length);
        }

        /**
         * 
         * 
         */
        public async Task<bool> isUserLoggedInAsync()
        {
            if (userLoggedInAlready == 1)
            {
                System.Diagnostics.Debug.WriteLine("User logged in already: " + currentToken);
                return true;
            }

            try
            {
                System.Diagnostics.Debug.WriteLine("Reading file..");
                String token = await ReadData("monkey.txt");
                System.Diagnostics.Debug.WriteLine("File read.");

                if (token != null && token != "")
                {
                    userLoggedInAlready = 1;
                    this.currentToken = token;
                    System.Diagnostics.Debug.WriteLine("User logged in: " + token);
                    return true;
                }
                else
                {
                    userLoggedInAlready = 0;
                    return false;
                }
                
            }
            catch (System.IO.FileNotFoundException e)
            {
                System.Diagnostics.Debug.WriteLine("Error reading from file: " + e.ToString());
                return false;
            }


        }


        class SquawkResponseContainer
        {
            public bool listened;

            public String sender;

            public List<String> thread_members;

            public String _id;

            public String recipient;

            public DateTime date;

        }

        class RecentSquawksResponse
        {
            public String error;

            public bool success;

            public List<SquawkResponseContainer> results;

        }




        /**
         * Returns an array containing the recent squawks a user has received.
         */
        public async Task<IEnumerable<SquawkMessage>> loadRecentSquawks()
        {


            System.Diagnostics.Debug.WriteLine("Loading recent squawks");

            String endPoint = apiPrefix + "/squawks/recent?args=";

            //generate the GET request
            String token = currentToken;

            String request = endPoint + WebUtility.UrlEncode("{\"token\" : \"" + token + "\"}");

            System.Diagnostics.Debug.WriteLine("Sending request: " + request);

            WebClient client = new WebClient();
            string response;
            try
            {
                response = await client.DownloadStringTaskAsync(new Uri(request));
            }
            catch (System.Net.WebException e)
            {
                System.Diagnostics.Debug.WriteLine("Caught an exception: " + e.ToString());
                return null;
            }
            //parse response.

            System.Diagnostics.Debug.WriteLine("Received Response: " + response);

            RecentSquawksResponse answer = JsonConvert.DeserializeObject<RecentSquawksResponse>(response);

            if (answer.error != null && answer.error != "")
            {
                System.Diagnostics.Debug.WriteLine("Error: " + answer.error);
                return null;
            }

            List <SquawkMessage> recentSquawks = new List<SquawkMessage>();

            System.Diagnostics.Debug.WriteLine("We were able to load " + answer.results.Count + " new squawks");

            for (int i = 0; i < answer.results.Count; i++)
            {
                System.Diagnostics.Debug.WriteLine("Loading " + i + "-th squawk message from " + answer.results[i].sender);
                SquawkResponseContainer x = answer.results[i];
                SquawkMessage y = new SquawkMessage(x.sender, x.date, x.thread_members, x._id);
                recentSquawks.Add(y);
            }


            return recentSquawks;



        }
    



    }
}
