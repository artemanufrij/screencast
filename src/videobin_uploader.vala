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

public class Uploader : Gtk.Window {
    class LLabel : Gtk.Label {
        public LLabel (string label) {
            this.set_halign (Gtk.Align.START);
            this.label = label;
        }

        public LLabel.indent (string label) {
            this (label);
            this.margin_left = 10;
        }

        public LLabel.markup (string label) {
            this (label);
            this.use_markup = true;
        }

        public LLabel.right (string label) {
            this.set_halign (Gtk.Align.END);
            this.label = label;
        }

        public LLabel.right_with_markup (string label) {
            this.set_halign (Gtk.Align.END);
            this.use_markup = true;
            this.label = label;
        }
    }

    public Uploader (File file) {
        this.title = "Upload to videobin.org";
        this.set_default_size (300, -1);
        this.window_position = Gtk.WindowPosition.CENTER;

        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.column_spacing = 12;
        grid.row_spacing = 5;

        var title = new Gtk.Entry ();
        title.placeholder_text = _("Optional");

        var description = new Gtk.Entry ();
        description.placeholder_text = _("Optional");

        var email = new Gtk.Entry ();
        email.placeholder_text = _("Optional");

        var img = new Gtk.Image.from_icon_name ("videobin", Gtk.IconSize.DIALOG);

        var upload_button = new Gtk.Button.with_label (_("Upload"));
        upload_button.get_style_context ().add_class ("suggested-action");

        var cancel = new Gtk.Button.from_stock (Gtk.Stock.CANCEL);
        cancel.margin_end = 6;

        var bbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        bbox.pack_end (upload_button, false, true, 0);
        bbox.pack_end (cancel, false, true, 0);

        email.set_tooltip_text (_("Your email address for relocating your videos"));

        upload_button.image = new Gtk.Image.from_icon_name ("mail-reply-sender", Gtk.IconSize.BUTTON);
        upload_button.can_default = true;

        this.set_default (upload_button);

        grid.attach (img, 0, 0, 1, 2);
        grid.attach (new LLabel ("Title"), 1, 0, 1, 1);
        grid.attach (title, 2, 0, 1, 1);
        grid.attach (new LLabel ("Email"), 1, 1, 1, 1);
        grid.attach (email, 2, 1, 1, 1);
        grid.attach (new LLabel ("Description"), 1, 2, 1, 1);
        grid.attach (description, 2, 2, 1, 1);
        grid.attach (bbox, 0, 3, 3, 1);

        this.add (grid);
        this.destroy.connect (Gtk.main_quit);

        cancel.clicked.connect (Gtk.main_quit);

        upload_button.clicked.connect (() => {
            string url;
            string path = file.get_path();

            if (path.has_prefix ("'") && path.has_suffix ("'"))
                path = path.substring (1, path.length - 2);

            string command = "curl -F\"api=1\" -F\"videoFile=@" + path + "\" ";

            if (email.text != "")
                command += "-F\"email=%s\" ".printf (email.text);

            if (title.text != "")
                command += "-F\"title=%s\" ".printf (title.text);

            if (description.text != "")
                command += "-F\"description=%s\" ".printf (description.text);

            command += "http://videobin.org/add";

            try {
                Process.spawn_command_line_sync (command, out url);
            } catch (Error e) {
                error (e.message);
            }

            try {
                if (url == null || url == "") {
                    warning("The upload has failed. Command: %s", command);
                } else {
                    Process.spawn_command_line_async ("sensible-browser " + url);
                }
            } catch (Error e) {
                error (e.message);
            }

            Gtk.main_quit ();
        });
    }
}

public static void main (string [] args) {
    Gtk.init (ref args);

    if (args.length <= 1) {
        warning ("You must provide a valid file path");
    } else {
        var path = args[1];
        var file = File.new_for_path (path);

        var dialog = new Uploader (file);
        dialog.show_all ();

        Gtk.main ();
    }
}

