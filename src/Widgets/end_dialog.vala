//
//  Copyright (C) 2011-2015 Eidete Developers
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Eidete.Widgets {
    public class EndDialog : Gtk.Dialog {
        private bool contractor;

        private EideteApp app;
        private Gtk.Button export;
        private Gtk.Grid grid;
        private Gtk.ListStore list;
        private Gtk.TreeView treeview;
        private File source;

        public EndDialog (EideteApp app) {
            this.app = app;
            this.window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        }

        private void build_ui () {
            this.set_default_size (600, 600);
            this.set_application (app);
            this.set_deletable (false);

            if (app.selectionarea != null)
                app.selectionarea.destroy ();

            if (app.keyview != null)
                app.keyview.destroy ();

            this.icon_name = "eidete";

            grid = new Gtk.Grid ();
            grid.margin_start = 12;
            grid.margin_end = 12;

            var content = (this.get_content_area () as Gtk.Box);

            var title = new Gtk.Label ("<span size='30000'>" + _("Recording complete") + "</span>");
            title.use_markup = true;
            title.halign = Gtk.Align.START;

            export = new Gtk.Button.with_label (_("Save"));
            export.image = new Gtk.Image.from_stock (Gtk.Stock.SAVE, Gtk.IconSize.BUTTON);
            export.get_style_context ().add_class ("suggested-action");
            export.can_default = true;

            this.set_default (export);

            var cancel = new Gtk.Button.with_label (_("Cancel"));
            cancel.image = new Gtk.Image.from_stock (Gtk.Stock.DELETE, Gtk.IconSize.BUTTON);
            cancel.margin_end = 6;

            var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            bbox.layout_style = Gtk.ButtonBoxStyle.END;
            bbox.homogeneous = true;

            bbox.pack_end (cancel, false, true, 0);
            bbox.pack_end (export, false, true, 0);

            list = new Gtk.ListStore (2, typeof (Gdk.Pixbuf), typeof (string));

            treeview = new Gtk.TreeView.with_model (list);
            treeview.headers_visible = false;
            treeview.hexpand = true;
            treeview.set_activate_on_single_click (false);
            treeview.row_activated.connect (on_contract_executed);

            var cell1 = new Gtk.CellRendererPixbuf ();
            cell1.set_padding (5, 15);

            treeview.insert_column_with_attributes (-1, "", cell1, "pixbuf", 0);

            var cell2 = new Gtk.CellRendererText ();
            cell2.set_padding (2, 15);

            treeview.insert_column_with_attributes (-1, "", cell2, "markup", 1);

            // contractor

            load_contracts ();

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.vexpand = true;
            scrolled.add (treeview);

            grid.attach (title, 0, 0, 2, 1);
            grid.attach (new Gtk.Label (""), 0, 2, 1, 1);

            grid.attach (scrolled, 0, 4, 1, 1);

            grid.attach (new Gtk.Label (""), 0, 5, 1, 1);
            grid.attach (bbox, 0, 6, 1, 1);

            source = File.new_for_path (app.settings.destination);

            if (contractor) {
                export.clicked.connect (on_contract_executed);
            } else {
                export.clicked.connect (() => {
                    save_file ();

                    this.destroy ();
                });
            }

            cancel.clicked.connect (() => {
                this.destroy ();
            });

            content.add (grid);
        }

        public void display () {
            build_ui ();

            show_all ();
        }

        private void on_contract_executed () {
            Gtk.TreePath path;

            treeview.get_cursor (out path, null);

            int index = int.parse (path.to_string ());

            execute_command (index);

            this.destroy ();
        }

        private void save_file () {
            var dialog = new Gtk.FileChooserDialog (_("Save"), null, Gtk.FileChooserAction.SAVE, Gtk.Stock.OK, Gtk.ResponseType.OK);
            dialog.set_current_name (source.get_basename ());

            var videos_folder = Environment.get_user_special_dir (UserDirectory.VIDEOS);

            dialog.set_current_folder (videos_folder);
            dialog.do_overwrite_confirmation = true;

            var res = dialog.run ();

            if (res == Gtk.ResponseType.OK) {
                var destination = File.new_for_path (dialog.get_filename ());

                try {
                    source.copy (destination, FileCopyFlags.OVERWRITE);
                } catch (GLib.Error e) {
                    stderr.printf ("Error: %s\n", e.message);
                }
            }

            dialog.destroy ();
        }

        // Using deprecated Contractor API. Necesserary to maintain luna compatibility
#if false
        private void execute_command_deprecated (int index) {
            string cmd = contracts_dep[index].lookup ("Exec");

            try {
                Process.spawn_command_line_async (cmd);
            } catch (Error e) {
                print (e.message);
            }
        }

        private HashTable<string,string>[] contracts_dep;

        private void load_contracts_deprecated () {
            // CARL deprecated Contractor API
            contracts_dep = Granite.Services.Contractor.get_contract (app.settings.destination, "video");

            if (contracts_dep == null || contracts_dep.length <= 1) {
                warning ("You should install and/or run contractor");

                contractor = false;

                var info = new InfoBar ();
                info.message_type = MessageType.WARNING;

                info.pack_start (new Label (_("Could not contact Contractor.")));

                grid.attach (info, 0, 3, 2, 1);

                export.label = _("Save");
            } else {
                contractor = true;

                for (var i = 0; i < contracts_dep.length; i++) {
                    TreeIter it;

                    list.append (out it);

                    Gdk.Pixbuf icon = null;

                    try {
                        icon = IconTheme.get_default ().load_icon (contracts_dep[i].lookup ("IconName"), 32, 0);
                    } catch (Error e) {
                        warning (e.message);
                    }

                    list.set (it, 0, icon, 1,
                            "<b>" + contracts_dep[i].lookup ("Name") +
                            "</b>\n" + contracts_dep[i].lookup ("Description"));
                }

                treeview.set_cursor (new TreePath.from_string ("0"), null, false);
            }
        }
#endif

        private Gee.List<Granite.Services.Contract> contracts;

        private int contracts_size = 0;

        private void execute_command (int index) {
            if(index == 0) {
                save_file ();
            } else {
                var contract = contracts.@get (index - 1);

                try {
                    contract.execute_with_file (source);
                } catch (Error e) {
                    warning (e.message);
                }
            }
        }

        private void load_contracts () {
            contracts_size = 0;

            try {
                contracts = Granite.Services.ContractorProxy.get_contracts_by_mime ("video");
            } catch (Error e) {
                warning (e.message);
            }

            if (contracts != null) {
                contractor = true;

                foreach (var contract in contracts) {
                    Gtk.TreeIter it;

                    list.append (out it);

                    Gdk.Pixbuf icon = null;

                    try {
                        icon = Gtk.IconTheme.get_default ().load_icon (contract.get_icon ().to_string (), 32, 0);

                    } catch (Error e) {
                        warning (e.message);
                    }

                    list.set (it, 0, icon, 1,
                            "<b>" + contract.get_display_name () + "</b>\n" +
                            contract.get_description ());

                    contracts_size++;
                }

                Gtk.TreeIter it;

                list.insert (out it, 0);

                Gdk.Pixbuf icon = null;

                try {
                    icon = Gtk.IconTheme.get_default ().load_icon ("document-save", 32, 0);
                } catch (Error e) {
                    warning (e.message);
                }

                list.set (it, 0, icon, 1,
                        "<b>" + _("Save file") + "</b>\n" +
                        ("Save the file onto a disk"));

                treeview.set_cursor (new Gtk.TreePath.from_string ("0"), null, false);

                export.label = _("Execute");
            }

            if (contracts_size == 0) {
                warning ("You should install and/or run contractor");

                contractor = false;

                var info = new Gtk.InfoBar ();
                info.message_type = Gtk.MessageType.WARNING;

                info.pack_start (new Gtk.Label (_("Could not contact Contractor.")));

                grid.attach (info, 0, 3, 2, 1);

                export.label = _("Save");
            }
        }
    }
}

