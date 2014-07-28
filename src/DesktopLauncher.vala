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

    public class DesktopLauncher : Gtk.SearchBar {

	/**
	 * The DesktopLauncher widget.
	*/

	public signal void launcher_closed();
	public signal void launcher_opened();
	
	private Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();

        private DesktopWindow parent_window;
        private Settings settings;
	
	private Gtk.Box container;
	
	private Gtk.SearchEntry search;
	
	private Gtk.Revealer results_revealer;
	private Gtk.Box results_container;
	private Gtk.Label no_results_found;
	private Gtk.Label internet_search;
	
	private Gtk.IconView results_view;
	private Gtk.ListStore results_list;
	
	private void on_search_changed() {
	    /**
	     * Fired when the search text has been changed.
	    */
	    
	    //this.show();
	    
	    if (this.search.text_length == 0) {
		
		this.results_list.clear();
		
		this.search_mode_enabled = false;
		this.results_revealer.reveal_child = false;
		
		this.launcher_closed();
		
		//this.set_child_visible(false);
		
		return;
	    } else {
		
		//this.set_child_visible(true);
		
		if (!this.results_revealer.reveal_child)
		    this.results_revealer.reveal_child = true;
	    }
	    
	    Gtk.TreeIter iter;
	    this.results_list.append(out iter);
	    Gdk.Pixbuf pixbuf = icon_theme.lookup_by_gicon(new ThemedIcon("gtk-save"),48,0).load_icon();
	    this.results_list.set(iter, 0, "LOL", 1, pixbuf);
	    
	    this.no_results_found.hide();
	    
	    this.internet_search.set_markup("Search in <i>Google</i>...");
	    
		
	}
	
	public bool open_launcher(Gtk.Widget widget, Gdk.EventKey event) {
	    /**
	     * Fired when we should open the launcher (triggered by a keypress)
	    */
	    
	    this.launcher_opened();
	    
	    this.handle_event(event);
	    
	    return true;
	}
	
	public DesktopLauncher(DesktopWindow parent_window, Settings settings) {
	    /**
	     * Constructs the DesktopLauncher.
	    */

	    Object();

            this.parent_window = parent_window;
            this.settings = settings;
	    
	    /* Build the container */
	    this.container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
	    this.add(this.container);
	    
	    /* Build the search entry */
	    this.search = new Gtk.SearchEntry();
	    this.container.pack_start(this.search, false, false, 0);
	    this.connect_entry(this.search);

	    /* Size */
	    this.search.set_size_request(600, -1);
	    
	    //this.pack_start(this.searchbar, false, false, 0);
	    
	    this.search.show();
	    this.show();
	    
	    /* Results */
	    this.results_revealer = new Gtk.Revealer();
	    this.results_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
	    this.results_revealer.add(this.results_container);
	    this.container.pack_start(this.results_revealer, false, false, 0);
	    
	    this.results_list = new Gtk.ListStore(2, typeof(string), typeof(Gdk.Pixbuf));
	    this.results_view = new Gtk.IconView.with_model(this.results_list);
	    this.results_view.set_model(this.results_list);
	    this.results_view.set_text_column(0);
	    this.results_view.set_pixbuf_column(1);
	    this.results_container.pack_start(this.results_view);
	    
	    /* "No results found" message */
	    this.no_results_found = new Gtk.Label("No results found.");
	    this.results_container.pack_start(this.no_results_found);
	    
	    this.internet_search = new Gtk.Label(null);
	    
	    
	    	    
	    /* Events */
	    this.search.search_changed.connect(this.on_search_changed);

	}

    }

}
