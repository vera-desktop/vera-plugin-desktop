/*
 * vera-plugin-desktop - desktop plugin for vera
 * Copyright (C) 2014  Eugenio "g7" Paolantonio and the Semplice Project
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Authors:
 *     Eugenio "g7" Paolantonio <me@medesimo.eu>
*/

using Vera;

namespace DesktopPlugin {
    
    enum BackgroundMode {
        COLOR = 1,
        TILE = 2,
        STRETCH = 3,
        SCREEN = 4,
        FIT = 5,
        CROP = 6,
        CENTER = 7;
    }
        

	public class DesktopBackground : Gtk.EventBox {

		/**
		 * The DesktopBackground widget. This is the main part of
		 * DesktopPlugin.
		 */
         
        private XlibDisplay xlib_display;
        
        private int monitor_number;

        private DesktopWindow parent_window;

        private bool painted = false;

        private Settings settings;

        private weak Gdk.RGBA background_color;
        private weak Gdk.Pixbuf pixbuf;
        
        public signal void menu_shown ();

        private bool on_button_pressed(Gdk.EventButton evnt) {
            
            message("Button pressed!");
            
            if (evnt.button == Gdk.BUTTON_PRIMARY) {
                /* If primary button (usually left), we need to regain focus */
                this.parent_window.set_focus(this);
            } else {
                /* Otherwise, forward the event to the root window (if we are on X) */
                
                if (evnt.button == Gdk.BUTTON_SECONDARY) {
                    /* That's probably the WM menu */
                    this.menu_shown();
                }
                
                this.xlib_display.send_to_root_window(evnt);
            }

            return true;
        }

		public DesktopBackground(DesktopWindow parent_window, Settings settings, int monitor_number) {
            /**
             * Constructs the DesktopBackground.
             */

            Object();
            
            /* Monitor number */
            this.monitor_number = monitor_number;
            
            /* Events */
            this.add_events(
                Gdk.EventMask.BUTTON_PRESS_MASK |
                Gdk.EventMask.BUTTON_RELEASE_MASK |
                Gdk.EventMask.KEY_PRESS_MASK |
                Gdk.EventMask.KEY_RELEASE_MASK |
                Gdk.EventMask.ENTER_NOTIFY_MASK |
                Gdk.EventMask.LEAVE_NOTIFY_MASK
            );
            this.can_focus = true;

            this.parent_window = parent_window;
            
            /* Xlibdisplay? */
            this.xlib_display = (XlibDisplay)this.parent_window.display;

            this.background_color = new Gdk.RGBA();

            this.settings = settings;


            this.set_app_paintable(true);

            this.button_press_event.connect(this.on_button_pressed);


		}

	}

}
