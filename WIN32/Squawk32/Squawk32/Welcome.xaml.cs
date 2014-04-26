using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;
using System.Security.Cryptography;
using Microsoft.Phone.Tasks;
using System.IO.IsolatedStorage;

namespace Squawk32
{
    public partial class Welcome : PhoneApplicationPage, SquawkInterfaceProtocol
    {
        public Welcome()
        {
            InitializeComponent();
            loading = false;
            hasGottenStarted = false;

            IsolatedStorageSettings settings = IsolatedStorageSettings.ApplicationSettings;
            if (settings.Contains("GeneratedPassword"))
            {
                settings.Remove("GeneratedPassword");
            }
            generatePassword();
        }

        public void userDidLogin()
        {
            System.Diagnostics.Debug.WriteLine("User Logged in succesfully.");
            NavigationService.Navigate(new Uri("/MainPage.xaml", UriKind.Relative));

        }

        private void generatePassword()
        {
            const int length = 5;
            RNGCryptoServiceProvider prng = new RNGCryptoServiceProvider();
            byte[] randBytes = new byte[length];
            prng.GetBytes(randBytes);
            const string chars = "abcdefghijklmnopqrstuvwxyz0123456789";
            string pw = "";
            for (int i = 0; i < length; i++)
            {
                pw += chars.Substring(randBytes[i] % chars.Length, 1);
            }
            generatedPassword = pw;
        }
        private string generatedPassword;

        private bool hasGottenStarted;

        public static string VerificationNumber = "646-576-7688";

        private void PickedNickname(object sender, RoutedEventArgs e)
        {
            VerificationTextPrompt.Text = String.Format("Now text {0} to {1} from your phone, then click Done.", generatedPassword, VerificationNumber);
            VerificationPromptPanel.Visibility = System.Windows.Visibility.Visible;

            SmsComposeTask smsComposeTask = new SmsComposeTask();
            smsComposeTask.To = "6465767688"; // Mention here the phone number to whom the sms is to be sent
            smsComposeTask.Body = generatedPassword; // the string containing the sms body
            smsComposeTask.Show(); // this will invoke the native sms edtior

            //need to save the current state....

            System.Diagnostics.Debug.WriteLine("Picked Nickname. Launched editor");
        }

        private void printf(String str)
        {
            System.Diagnostics.Debug.WriteLine(str);
        }




        private void Application_Deactivated(object sender, DeactivatedEventArgs e)
        {
            IsolatedStorageSettings settings = IsolatedStorageSettings.ApplicationSettings;

            System.Diagnostics.Debug.WriteLine("OnNavigateFrom called... Save information");
            if (hasGottenStarted)
            {
                //persist the information...
                settings.Add("GeneratedPassword", generatedPassword);
                settings.Save();
            }
        }

        private void Application_Activated(object sender, ActivatedEventArgs e)
        {
            System.Diagnostics.Debug.WriteLine("OnNavigatedTo called...");

            IsolatedStorageSettings settings = IsolatedStorageSettings.ApplicationSettings;
            if (settings.Contains("GeneratedPassword"))
            {
                //there is a password to recover
                String password = settings["GeneratedPassword"] as String;
                VerificationTextPrompt.Text = String.Format("Now text {0} to {1} from your phone, then click Done.", password, VerificationNumber);
                VerificationPromptPanel.Visibility = System.Windows.Visibility.Visible;
                printf("Succeeded in loading generated password key");
            }
            else
            {
                VerificationPromptPanel.Visibility = System.Windows.Visibility.Collapsed;
                //no data was stored
                printf("Could not load generated password key");
            }
        }


        private bool _loading = false;
        private bool loading
        {
            set
            {
                LoadingIndicator.Opacity = value? 1 : 0;
                _loading = value;
            }
            get
            {
                return _loading;
            }
        }

        private void TryLogin(object sender, RoutedEventArgs e)
        {
            if (loading) return;
            loading = true;
            SquawkInterface sharedInterface = SquawkInterface.getSharedInterface();
            sharedInterface.tryUserLoginWithSecret(generatedPassword);

            sharedInterface.messageDelegate = this;
            sharedInterface.isUserLoggedInCallback();
            
            loading = false;
        }

        private void alertNotVerifiedYet()
        {
            System.Windows.MessageBox.Show("We haven't received your text yet. Wait a little while, or check to make sure it went through.", "Just a sec...", MessageBoxButton.OK);
        }
    }
}