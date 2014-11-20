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
	
	public const int ITEM_WIDTH = 50;
	public const int ITEM_HEIGHT = 50;
	
	private int max_item_number;
	
	private int current_item = 0;
	private int current_page = 1;

	public signal void launcher_closed();
	public signal void launcher_opened();
	
	private Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();

        private DesktopWindow parent_window;
        private Settings settings;
	private ApplicationLauncher application_launcher;
	
	private Gtk.Box container;
	
	private Gtk.SearchEntry search;
	
	private Gtk.Revealer results_revealer;
	private Gtk.Box results_container;
	private Gtk.Label no_results_found;
	private Gtk.Label internet_search;
	
	private Gtk.IconView results_view;
	private Gtk.ListStore results_list;
	private Gtk.TreeModelFilter results_filter;
	
	private LauncherPages launcher_pages;
	
	private bool searching = false;
	private string start_text = null;
	
	private void on_search_changed() {
	    /**
	     * Fired when the search text has been changed.
	    */
	    
	    //this.show();
	    
	    if (this.search.text_length == 0) {
		
		this.results_list.clear();
		
		this.search_mode_enabled = false;
		this.results_revealer.reveal_child = false;
		
		this.start_text = null;
		
		this.launcher_closed();
				
		//this.set_child_visible(false);
		
		return;
	    } else {
		
		//this.set_child_visible(true);
		
		if (!this.results_revealer.reveal_child)
		    this.results_revealer.reveal_child = true;
	    }
	    
	    string keyword = this.search.get_text().down();
	    
	    if (this.start_text != null && keyword.has_prefix(this.start_text)) {
		/* Start text still valid, thus we need only to filter */
		this.current_item = 0;
		this.results_filter.refilter();
	    } else {
		/* Start text not valid anymore, search again */
		this.results_list.clear();
		this.start_text = keyword;
	        this.application_launcher.search(keyword);
	    }

	    this.no_results_found.hide();
	    
	    this.internet_search.set_markup("Search in <i>Google</i>...");
	    
	}
	
	private bool determine_item_visibility(Gtk.TreeModel model, Gtk.TreeIter iter) {
	    /**
	     * Returns True if the item linked at iter should be visible given
	     * the current keyword, False if not.
	    */
	    
	    int item_number;

	    if (!this.searching) {
		
		Value infos;
		model.get_value(iter, 3, out infos);
		
		if (!(
		    ApplicationLauncher.item_matches_keyword(
			this.search.get_text(),
			(DesktopAppInfo)infos
		    )
		)) {
		    return false;
		}
		
		/* We need to update the count */
		this.current_item++;
		//((Gtk.ListStore)model).set_value(iter, 4, this.current_item);
		
		item_number = this.current_item;
	    } else {
		Value count;
		model.get_value(iter, 4, out count);
		
		item_number = (int)count;
	    }
	    
	    Value name;
	    model.get_value(iter, 0, out name);
	    message("Item number for %s is %d", (string)name, item_number);
	    
	    message("Max item number * current_page: %d", this.max_item_number*this.current_page);
	    message("Max item number * current_page-1: %d", this.max_item_number*(this.current_page-1));

	    if (item_number > this.max_item_number*this.current_page || item_number <= this.max_item_number*(this.current_page-1)) {
		/* We need to *force* hide this item */
		message("Hiding");
		return false;
	    }
	    
	    /* Here? ok! */
	    message("Showing");
	    return true;
	}
	
	private void on_search_started() {
	    /**
	     * Fired when the actual search has been started.
	    */
	    
	    if (!this.search_mode_enabled)
		return;
	    
	    message("Search started");
	    
	    this.searching = true;
	    this.current_item = 0;
	    
	}
	
	private void on_search_finished() {
	    /**
	     * Fired when the search finished.
	    */

	    if (!this.search_mode_enabled)
		return;

	    message("Search finished");
	    
	    this.searching = false;
	    
	    message("num pages %d", (int)Math.ceil(this.current_item / this.max_item_number));
	    this.launcher_pages.update_page_number((int)Math.ceil(this.current_item / this.max_item_number));

	}
	
	private void on_application_found(DesktopAppInfo? app) {
	    /**
	     * Fired when the ApplicationLauncher has found a suitable
	     * application.
	    */
	    
	    if (!this.search_mode_enabled || app == null)
		return;
	    
	    Gtk.TreeIter iter;
	    this.results_list.append(out iter);
	    
	    Gdk.Pixbuf pixbuf = icon_theme.lookup_by_gicon(app.get_icon(),48,0).load_icon();
	    this.current_item++;
	    this.results_list.set(iter, 0, app.get_name(), 1, pixbuf, 2, app.get_description(), 3, app, 4, this.current_item);

/*
	    this.results_list.append(out iter);
	    this.current_item++;
	    this.results_list.set(iter, 0, app.get_name(), 1, pixbuf, 2, app.get_description(), 3, app, 4, this.current_item);


	    this.results_list.append(out iter);
	    this.current_item++;
	    this.results_list.set(iter, 0, app.get_name(), 1, pixbuf, 2, app.get_description(), 3, app, 4, this.current_item);
*/
	    

	}
	
	private void on_launcher_page_changed(int new_page) {
	    /**
	     * Fired when the page has been changed.
	    */
	    
	    message("New page! %d", new_page);
	    
	    this.current_page = new_page;
	    this.current_item = 0;
	    this.results_filter.refilter();
	    
	}
	
	private void on_item_activated(Gtk.TreePath path) {
	    /**
	     * Fired when an item has been activated.
	    */
	    
	    Gtk.TreeIter iter;
	    this.results_list.get_iter(out iter, path);
	    
	    Value infos;
	    this.results_list.get_value(iter, 3, out infos);
	    
	    new Launcher(((DesktopAppInfo)infos).get_commandline().split(" ")).launch();
	    
	    /* Close everything */
	    this.search.set_text("");
	    
	}
	
	public bool open_launcher(Gtk.Widget widget, Gdk.EventKey event) {
	    /**
	     * Fired when we should open the launcher (triggered by a keypress)
	    */
	    
	    this.launcher_opened();
	    
	    this.handle_event(event);
	    
	    return true;
	}
	
	public DesktopLauncher(DesktopWindow parent_window, Settings settings, ApplicationLauncher application_launcher) {
	    /**
	     * Constructs the DesktopLauncher.
	    */

	    Object();
	    
	    this.name = "VeraDesktopLauncher";

            this.parent_window = parent_window;
            this.settings = settings;
	    this.application_launcher = application_launcher;
	    
	    /* Calculate max_item_number */
	    int max_columns, max_rows;
	    max_columns = (int)Math.floor(this.parent_window.screen_size.width / ITEM_WIDTH);
	    max_rows = (int)Math.floor((this.parent_window.screen_size.height*70)/100 / ITEM_HEIGHT);
	    this.max_item_number = max_columns+max_rows;
	    
	    message("max item number %d", this.max_item_number);
	    
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
	    
	    this.results_list = new Gtk.ListStore(
		5,
		typeof(string),
		typeof(Gdk.Pixbuf),
		typeof(string),
		typeof(DesktopAppInfo),
		typeof(int)
	    );
	    this.results_filter = new Gtk.TreeModelFilter(this.results_list, null);
	    this.results_filter.set_visible_func(this.determine_item_visibility);
	    /*
	    this.results_scrolledwindow.set_size_request(
		-1,
		500
	    );
	    this.results_scrolledwindow.set_min_content_height(
		//200 : 100 = x : 70
		(this.parent_window.screen_size.height*20)/100
	    );
	    */
	    this.results_view = new Gtk.IconView.with_model(this.results_filter);
	    this.results_view.set_activate_on_single_click(true);
	    this.results_view.set_text_column(0);
	    this.results_view.set_pixbuf_column(1);
	    this.results_view.set_tooltip_column(2);
	    this.results_view.set_item_width(55);
	    this.results_view.set_item_padding(2);
	    this.results_container.pack_start(this.results_view);

	    /* Pages */
	    this.launcher_pages = new LauncherPages();
	    this.launcher_pages.page_changed.connect(this.on_launcher_page_changed);
	    this.results_container.pack_start(this.launcher_pages, false, false, 5);

	    /* "No results found" message */
	    this.no_results_found = new Gtk.Label("No results found.");
	    this.results_container.pack_start(this.no_results_found);
	    
	    this.internet_search = new Gtk.Label(null);
	    
	    
	    
	    /* Events */
	    this.results_view.item_activated.connect(this.on_item_activated);
	    this.search.search_changed.connect(this.on_search_changed);
	    this.application_launcher.search_started.connect(this.on_search_started);
	    this.application_launcher.application_found.connect(this.on_application_found);
	    this.application_launcher.search_finished.connect(this.on_search_finished);

	}

    }

}
