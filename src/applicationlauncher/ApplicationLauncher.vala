using Vera;

namespace DesktopPlugin {

	public class ApplicationLauncher : Object {
		
		/**
		 * A UI toolkit-agnostic application launcher.
		*/
		
		public bool enabled { get; private set; }
		
		private GMenu.Tree tree;
		private GMenu.TreeDirectory root;
		
		public signal void search_started();
		public signal void application_found(DesktopAppInfo? app);
		public signal void search_finished();
		
		private Rand random = new Rand();
		private uint SEARCH_ID;
		
		public ApplicationLauncher() {
			/**
			 * Constructs this class.
			*/
			
			/* FIXME: Make this configurable */
			this.enabled = true;
			
			this.tree = new GMenu.Tree(
				"%sapplications.menu".printf(
					(
						(Environment.get_variable("XDG_MENU_PREFIX") != null) ?
						Environment.get_variable("XDG_MENU_PREFIX") :
						"vera-"
					)
				),
				GMenu.TreeFlags.NONE
			);
			
			/* Load */
			try {
				/* Are there any async methods? */
				this.tree.load_sync();
			} catch (Error e) {
				warning("Unable to load ApplicationLauncher: %s", e.message);
				this.enabled = false;
			}
			
			this.root = this.tree.get_root_directory();
		}
		
		public static bool item_matches_keyword(string keyword, DesktopAppInfo infos) {
			/**
			 * Returns true if the informations in the given DesktopAppInfo matches
			 * the given keyword, false if not.
			*/
			
			string name, description;
			name = infos.get_name();
			description = infos.get_description();
			
			if ((name != null && keyword.down() in name.down()) || (description != null && keyword.down() in description.down())) {
				/* Yay */
				
				return true;
			} else {
				return false;
			}
		}
		
		public void search(string keyword, GMenu.TreeDirectory? directory = null) {
			/**
			 * Makes an application search using the specified keyword.
			 * 
			 * This method invokes application_found() whenever it finds an
			 * application matching the keyword, so to actually make something
			 * useful you must subscribe to that signal too.
			*/
			
			uint internal_id = this.random.next_int();
			this.SEARCH_ID = internal_id;
			
			if (directory == null)
				this.search_started();
			
			GMenu.TreeIter iter = ((directory != null) ? directory : this.root).iter();
			GMenu.TreeItemType type;
			string name, description;
			while ((type = iter.next()) != GMenu.TreeItemType.INVALID) {
				
				/* Still valid? */
				if (this.SEARCH_ID != internal_id)
					/* No. */
					return;
				
				if (type == GMenu.TreeItemType.DIRECTORY) {
					/* Directory, re run this method on it */
					
					this.search(keyword, iter.get_directory());
					
				} else if (type == GMenu.TreeItemType.ENTRY) {
					/* Entry */
					
					DesktopAppInfo infos = iter.get_entry().get_app_info();
					
					if (infos != null && item_matches_keyword(keyword, infos))  {
						/* Yay */
						
						this.application_found(infos);
						
					}
					
				}
			}
			
			//if (directory == null) {
			if (true) {
				message("ECCHEPPALLE HO FINITO");
				this.search_finished();
			}
			
		}
		
	}

}
