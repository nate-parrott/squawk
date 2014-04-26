using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;
using Squawk32.Resources;
using System.Threading.Tasks;

namespace Squawk32
{
    public partial class MainPage : PhoneApplicationPage
    {
        // Constructor
        public MainPage()
        {
            InitializeComponent();

            // Sample code to localize the ApplicationBar
            //BuildLocalizedApplicationBar();

            reload();
        }

        protected override void OnBackKeyPress(System.ComponentModel.CancelEventArgs e)
        {
            e.Cancel = true;
            //there is no going back from this page!
        }

        public void reload()
        {
            if (loading) return;
            loading = true;
            SquawkListManager.reload().ContinueWith(t => {
                loading = false;
                SquawkList.ItemsSource = new List<Squawker>(t.Result);
            }, TaskScheduler.FromCurrentSynchronizationContext());
        }

        private bool _loading;
        public bool loading
        {
            set
            {
                _loading = value;
                LoadingIndicator.Opacity = _loading ? 1.0 : 0.0;

            }
            get { return _loading; }
        }

        private void SquawkList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {

        }

        // Sample code for building a localized ApplicationBar
        //private void BuildLocalizedApplicationBar()
        //{
        //    // Set the page's ApplicationBar to a new instance of ApplicationBar.
        //    ApplicationBar = new ApplicationBar();

        //    // Create a new button and set the text value to the localized string from AppResources.
        //    ApplicationBarIconButton appBarButton = new ApplicationBarIconButton(new Uri("/Assets/AppBar/appbar.add.rest.png", UriKind.Relative));
        //    appBarButton.Text = AppResources.AppBarButtonText;
        //    ApplicationBar.Buttons.Add(appBarButton);

        //    // Create a new menu item with the localized string from AppResources.
        //    ApplicationBarMenuItem appBarMenuItem = new ApplicationBarMenuItem(AppResources.AppBarMenuItemText);
        //    ApplicationBar.MenuItems.Add(appBarMenuItem);
        //}
    }
}